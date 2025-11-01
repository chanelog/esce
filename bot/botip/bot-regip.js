require('dotenv').config();
const TelegramBot = require('node-telegram-bot-api');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

// Konfigurasi dari .env
const TOKEN = process.env.BOT_TOKEN;
const ADMIN_CHAT_ID = process.env.ADMIN_CHAT_ID;
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD;
const ALLOWED_USERS = process.env.ALLOWED_USERS ? process.env.ALLOWED_USERS.split(',').map(id => id.trim()) : [ADMIN_CHAT_ID];

const GITHUB_USER = process.env.GITHUB_USER;
const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
const GITHUB_REPO = process.env.GITHUB_REPO;
const GITHUB_EMAIL = process.env.GITHUB_EMAIL;

const UBUNTU_INSTALL_SCRIPT = process.env.UBUNTU_INSTALL_SCRIPT;
const DEBIAN_INSTALL_SCRIPT = process.env.DEBIAN_INSTALL_SCRIPT;

// Validasi config
if (!TOKEN || !ADMIN_CHAT_ID || !GITHUB_TOKEN) {
    console.error('❌ ERROR: Missing required environment variables');
    console.log('Please check your .env file');
    process.exit(1);
}

// Path files
const DATA_DIR = '/root/vps-data';
const IPX_FILE = path.join(DATA_DIR, 'ipx');
const IP_FILE = path.join(DATA_DIR, 'ip');
const GIT_DIR = path.join(DATA_DIR, 'repo');
const USERS_FILE = path.join(DATA_DIR, 'allowed_users.json');
const ENV_FILE = path.join(process.cwd(), '.env');

// Inisialisasi bot
const bot = new TelegramBot(TOKEN, { polling: true });

console.log('🤖 Bot VPS Manager sedang berjalan...');
console.log('📊 Admin Chat ID:', ADMIN_CHAT_ID);
console.log('🔗 GitHub User:', GITHUB_USER);
console.log('👥 Allowed Users:', ALLOWED_USERS);

// Inisialisasi directory dan files
if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
}

// Load allowed users dari file
function loadAllowedUsers() {
    try {
        if (fs.existsSync(USERS_FILE)) {
            const data = fs.readFileSync(USERS_FILE, 'utf8');
            return JSON.parse(data);
        }
    } catch (error) {
        console.error('❌ Error loading users file:', error);
    }
    
    // Default users dari .env
    return {
        allowedUsers: ALLOWED_USERS,
        temporaryAccess: {}, // { userId: timestamp }
        pendingRequests: []
    };
}

// Save allowed users ke file
function saveAllowedUsers(usersData) {
    try {
        fs.writeFileSync(USERS_FILE, JSON.stringify(usersData, null, 2));
        return true;
    } catch (error) {
        console.error('❌ Error saving users file:', error);
        return false;
    }
}

// Update environment variable di .env file
function updateEnvVariable(key, value) {
    try {
        let envContent = '';
        if (fs.existsSync(ENV_FILE)) {
            envContent = fs.readFileSync(ENV_FILE, 'utf8');
        }
        
        const lines = envContent.split('\n');
        let found = false;
        const newLines = lines.map(line => {
            if (line.startsWith(key + '=')) {
                found = true;
                return `${key}=${value}`;
            }
            return line;
        });
        
        if (!found) {
            newLines.push(`${key}=${value}`);
        }
        
        fs.writeFileSync(ENV_FILE, newLines.join('\n'));
        
        // Update process.env juga
        process.env[key] = value;
        
        console.log(`✅ Environment variable ${key} berhasil diupdate`);
        return true;
    } catch (error) {
        console.error(`❌ Error updating ${key}:`, error);
        return false;
    }
}

// Cek apakah user adalah admin
function isAdmin(userId) {
    return userId.toString() === ADMIN_CHAT_ID;
}

// Cek apakah user memiliki akses sementara untuk add IP
function hasTemporaryAccess(userId) {
    const usersData = loadAllowedUsers();
    const userAccess = usersData.temporaryAccess[userId];
    
    if (userAccess) {
        // Cek apakah akses masih valid (1 jam)
        const now = Date.now();
        const accessTime = userAccess.timestamp;
        const oneHour = 60 * 60 * 1000; // 1 jam dalam milliseconds
        
        if (now - accessTime < oneHour) {
            return true;
        } else {
            // Hapus akses yang sudah expired
            delete usersData.temporaryAccess[userId];
            saveAllowedUsers(usersData);
            return false;
        }
    }
    return false;
}

// Beri akses sementara untuk user
function grantTemporaryAccess(userId) {
    const usersData = loadAllowedUsers();
    usersData.temporaryAccess[userId] = {
        timestamp: Date.now(),
        grantedBy: 'system'
    };
    return saveAllowedUsers(usersData);
}

// Hapus akses sementara setelah add IP
function revokeTemporaryAccess(userId) {
    const usersData = loadAllowedUsers();
    if (usersData.temporaryAccess[userId]) {
        delete usersData.temporaryAccess[userId];
        return saveAllowedUsers(usersData);
    }
    return true;
}

// Helper function untuk execute command
function runCommand(command) {
    return new Promise((resolve, reject) => {
        exec(command, { timeout: 30000 }, (error, stdout, stderr) => {
            if (error) {
                reject(error);
                return;
            }
            resolve(stdout || stderr);
        });
    });
}

// Setup Git config
async function setupGit() {
    try {
        await runCommand(`git config --global user.email "${GITHUB_EMAIL}"`);
        await runCommand(`git config --global user.name "${GITHUB_USER}"`);
        console.log('✅ Git config setup completed');
    } catch (error) {
        console.error('❌ Git setup error:', error);
    }
}

// Clone repository dari GitHub
async function cloneRepo() {
    try {
        if (fs.existsSync(GIT_DIR)) {
            fs.rmSync(GIT_DIR, { recursive: true });
        }
        
        const repoUrl = `https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${GITHUB_REPO}.git`;
        await runCommand(`git clone ${repoUrl} ${GIT_DIR}`);
        console.log('✅ Repository cloned successfully');
        return true;
    } catch (error) {
        console.error('❌ Clone error:', error);
        return false;
    }
}

// Push changes ke GitHub
async function pushToGitHub(message) {
    try {
        await runCommand(`cd ${GIT_DIR} && git add .`);
        await runCommand(`cd ${GIT_DIR} && git commit -m "${message}"`);
        await runCommand(`cd ${GIT_DIR} && git push origin main`);
        console.log('✅ Changes pushed to GitHub');
        return true;
    } catch (error) {
        console.error('❌ Push error:', error);
        return false;
    }
}

// Check GitHub connection
async function checkGitHubConnection() {
    try {
        const result = await runCommand(`curl -s -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/user"`);
        const userInfo = JSON.parse(result);
        
        if (userInfo && userInfo.login) {
            return { success: true, message: `✅ Koneksi GitHub OK\n<b>User:</b> ${userInfo.login}\n<b>Token:</b> ${GITHUB_TOKEN.substring(0, 8)}...` };
        } else {
            return { success: false, message: '❌ Gagal terhubung ke GitHub' };
        }
    } catch (error) {
        return { success: false, message: '❌ Gagal terhubung ke GitHub' };
    }
}

// Load data dari GitHub
async function loadDataFromGitHub() {
    try {
        const cloned = await cloneRepo();
        if (!cloned) return false;

        // Copy files dari repo ke local
        const repoIpx = path.join(GIT_DIR, 'ipx');
        const repoIp = path.join(GIT_DIR, 'ip');
        
        if (fs.existsSync(repoIpx)) {
            fs.copyFileSync(repoIpx, IPX_FILE);
        }
        if (fs.existsSync(repoIp)) {
            fs.copyFileSync(repoIp, IP_FILE);
        }
        
        return true;
    } catch (error) {
        console.error('❌ Load data error:', error);
        return false;
    }
}

// Save data ke GitHub
async function saveDataToGitHub(commitMessage) {
    try {
        const cloned = await cloneRepo();
        if (!cloned) return false;

        // Copy files dari local ke repo
        if (fs.existsSync(IPX_FILE)) {
            fs.copyFileSync(IPX_FILE, path.join(GIT_DIR, 'ipx'));
        }
        if (fs.existsSync(IP_FILE)) {
            fs.copyFileSync(IP_FILE, path.join(GIT_DIR, 'ip'));
        }

        return await pushToGitHub(commitMessage);
    } catch (error) {
        console.error('❌ Save data error:', error);
        return false;
    }
}

// Baca data IP dari file
function readIPData() {
    const ips = [];
    
    if (fs.existsSync(IPX_FILE)) {
        const content = fs.readFileSync(IPX_FILE, 'utf8');
        const lines = content.split('\n');
        
        for (const line of lines) {
            if (line.startsWith('###')) {
                const parts = line.split(' ').filter(part => part.trim() !== '');
                if (parts.length >= 4) {
                    ips.push({
                        username: parts[1],
                        expired: parts[2],
                        ip: parts[3],
                        status: parts[4] || ''
                    });
                }
            }
        }
    }
    
    return ips;
}

// Tambah IP baru
function addIP(username, ip, days) {
    const expired = new Date();
    expired.setDate(expired.getDate() + parseInt(days));
    const expiredStr = expired.toISOString().split('T')[0];
    
    // Tambah ke ipx file
    if (!fs.existsSync(IPX_FILE)) {
        fs.writeFileSync(IPX_FILE, '# ADMIN\n');
    }
    
    let ipxContent = fs.readFileSync(IPX_FILE, 'utf8');
    ipxContent += `### ${username} ${expiredStr} ${ip} @VIP\n`;
    fs.writeFileSync(IPX_FILE, ipxContent);
    
    // Tambah ke ip file
    if (!fs.existsSync(IP_FILE)) {
        fs.writeFileSync(IP_FILE, '# SSHWS\n');
    }
    
    let ipContent = fs.readFileSync(IP_FILE, 'utf8');
    ipContent += `### ${username} ${expiredStr} ${ip} ON SSHWS @VIP\n`;
    fs.writeFileSync(IP_FILE, ipContent);
    
    return expiredStr;
}

// Hapus IP
function deleteIP(ip) {
    let deleted = false;
    
    // Hapus dari ipx file
    if (fs.existsSync(IPX_FILE)) {
        let ipxContent = fs.readFileSync(IPX_FILE, 'utf8');
        const lines = ipxContent.split('\n');
        const newLines = lines.filter(line => !line.includes(ip));
        
        if (newLines.length !== lines.length) {
            fs.writeFileSync(IPX_FILE, newLines.join('\n'));
            deleted = true;
        }
    }
    
    // Hapus dari ip file
    if (fs.existsSync(IP_FILE)) {
        let ipContent = fs.readFileSync(IP_FILE, 'utf8');
        const lines = ipContent.split('\n');
        const newLines = lines.filter(line => !line.includes(ip));
        
        if (newLines.length !== lines.length) {
            fs.writeFileSync(IP_FILE, newLines.join('\n'));
            deleted = true;
        }
    }
    
    return deleted;
}

// Perpanjang IP
function renewIP(ip, additionalDays) {
    let renewed = false;
    
    // Update di ipx file
    if (fs.existsSync(IPX_FILE)) {
        let ipxContent = fs.readFileSync(IPX_FILE, 'utf8');
        const lines = ipxContent.split('\n');
        
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].includes(ip)) {
                const parts = lines[i].split(' ').filter(part => part.trim() !== '');
                if (parts.length >= 4) {
                    const oldExpired = parts[2];
                    const newExpired = new Date(oldExpired);
                    newExpired.setDate(newExpired.getDate() + parseInt(additionalDays));
                    const newExpiredStr = newExpired.toISOString().split('T')[0];
                    
                    lines[i] = lines[i].replace(oldExpired, newExpiredStr);
                    renewed = true;
                }
            }
        }
        
        if (renewed) {
            fs.writeFileSync(IPX_FILE, lines.join('\n'));
        }
    }
    
    // Update di ip file
    if (fs.existsSync(IP_FILE)) {
        let ipContent = fs.readFileSync(IP_FILE, 'utf8');
        const lines = ipContent.split('\n');
        
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].includes(ip)) {
                const parts = lines[i].split(' ').filter(part => part.trim() !== '');
                if (parts.length >= 4) {
                    const oldExpired = parts[2];
                    const newExpired = new Date(oldExpired);
                    newExpired.setDate(newExpired.getDate() + parseInt(additionalDays));
                    const newExpiredStr = newExpired.toISOString().split('T')[0];
                    
                    lines[i] = lines[i].replace(oldExpired, newExpiredStr);
                    renewed = true;
                }
            }
        }
        
        if (renewed) {
            fs.writeFileSync(IP_FILE, lines.join('\n'));
        }
    }
    
    return renewed;
}

// Format data IP untuk ditampilkan
function formatIPList() {
    const ips = readIPData();
    const now = new Date();
    
    if (ips.length === 0) {
        return '📭 Tidak ada data IP VPS terdaftar';
    }
    
    let result = '<b>📋 DAFTAR IP VPS</b>\n\n';
    result += '<pre>';
    result += '┌──────────────────────────────────────────────┐\n';
    result += '│ USERNAME         EXPIRED     IP VPS         │\n';
    result += '├──────────────────────────────────────────────┤\n';
    
    ips.forEach(ipData => {
        const expired = new Date(ipData.expired);
        const isExpired = expired < now;
        
        const username = ipData.username.padEnd(15);
        const expiredStr = ipData.expired.padEnd(12);
        const ip = ipData.ip.padEnd(15);
        
        if (isExpired) {
            result += `│ ❌ ${username} ${expiredStr} ${ip} │\n`;
        } else {
            result += `│ ✅ ${username} ${expiredStr} ${ip} │\n`;
        }
    });
    
    result += '└──────────────────────────────────────────────┘\n';
    result += '</pre>';
    
    return result;
}

// Generate script install berdasarkan OS
function generateInstallScript(osType, ipAddress, username) {
    let script = '';
    
    if (osType === 'ubuntu') {
        script = UBUNTU_INSTALL_SCRIPT;
    } else if (osType === 'debian') {
        script = DEBIAN_INSTALL_SCRIPT;
    }
    
    const installMessage = `
🔄 <b>SCRIPT INSTALL UNTUK VPS</b>

🌐 <b>IP VPS:</b> <code>${ipAddress}</code>
👤 <b>Username:</b> <code>${username}</code>
📦 <b>OS:</b> ${osType === 'ubuntu' ? 'Ubuntu' : 'Debian'}

📝 <b>Salin script berikut dan jalankan di VPS:</b>

<pre><code>${script}</code></pre>

<b>Cara penggunaan:</b>
1. SSH ke VPS: <code>ssh root@${ipAddress}</code>
2. Paste dan jalankan script di atas
3. Tunggu hingga proses install selesai
4. VPS siap digunakan!

⚠️ <b>Pastikan VPS sudah terinstall OS Ubuntu/Debian fresh</b>
    `;
    
    return installMessage;
}

// Format nama user
function formatUserName(user) {
    if (user.first_name && user.last_name) {
        return `${user.first_name} ${user.last_name}`;
    } else if (user.first_name) {
        return user.first_name;
    } else if (user.username) {
        return `@${user.username}`;
    } else {
        return 'User';
    }
}

// Header dengan info user
function getUserInfoHeader(user) {
    const userName = formatUserName(user);
    const userId = user.id;
    const currentTime = new Date().toLocaleString('id-ID', {
        timeZone: 'Asia/Jakarta',
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });

    const userStatus = isAdmin(userId) ? '👑 ADMIN' : '👤 USER';

    return `
<b>📊 IP VPS ACCESS MANAGEMENT BOT</b>

👋 Halo, <b>${userName}</b>!
🆔 ID Telegram: <code>${userId}</code>
👤 Status: <b>${userStatus}</b>
🕐 ${currentTime}

<b>Selamat datang di bot izin IP PX STORE</b>
🌟 FITUR UTAMA BOT:
✅ Izin IP VPS Otomatis & Cepat
✅ Hapus Izin IP Sesuka Hati
✅ Lihat Daftar Member Aktif
✅ Anti Ribet, Sepenuhnya Otomatis

💳 <b>SEWA AUTOSCRIPT:</b>
• 1 IP → Rp 15.000 / Bulan
• 2 IP → Rp 25.000 / Bulan
• 3 IP → Rp 35.000 / Bulan
• LIFETIME → Rp 200.000 (Bebas Sewa Selamanya!)
• OPENSOURCE → Rp 350.000 (Tanpa Bot Seller)
• FULL OPENSOURCE → Rp 500.000 (Include Bot Seller)
• MENYEWAKAN JUGA BOT SELLER ONLY, PM ADMIN

📌 <b>CATATAN PENTING:</b>
➡️ Khusus untuk pengguna Script Bot izin IP.
➡️ Jangan lupa Sync Data jika baru pertama kali install.
➡️ Butuh bantuan? Password verifikasi ada di PM Admin.

👨‍💻 Dev Script: <b>PeyxDev</b>

Pilih aksi yang ingin kamu lakukan di bawah ini: 👇
    `;
}

// Main Menu dengan buttons
function showMainMenu(chatId, user) {
    const menuText = getUserInfoHeader(user);

    const options = {
        reply_markup: {
            inline_keyboard: [
                [
                    { text: '📋 LIST IP', callback_data: 'list_ip' },
                    { text: '🌐 CHECK GITHUB', callback_data: 'check_github' }
                ],
                [
                    { text: '➕ ADD IP', callback_data: 'add_ip' },
                    { text: '🗑️ DELETE IP', callback_data: 'delete_ip' },   
                ],
                [
                    { text: '🔄 SYNC DATA', callback_data: 'sync_data' },
                    { text: '🔄 RENEW IP', callback_data: 'renew_ip' }
                 ],
                [
                    { text: '🔄 REFRESH BOT', callback_data: 'refresh_bot' },
                    { text: '🆘 HELP', callback_data: 'help' }
                ],
                isAdmin(user.id.toString()) ? [
                    { text: '⚙️ ADMIN SETTINGS', callback_data: 'admin_settings' }
                ] : [],
                [
                    { text: '👨‍💻 ADMIN', url: 'https://t.me/frel01' }
                ]
            ].filter(row => row.length > 0),
        },
        parse_mode: 'HTML'
    };

    bot.sendMessage(chatId, menuText, options);
}

// Admin Menu
function showAdminMenu(chatId, user) {
    const adminText = `
<b>⚙️ MENU ADMIN</b>

👋 Halo, <b>${formatUserName(user)}</b>!
👑 Status: <b>ADMIN</b>

<b>Fitur Admin:</b>
• Edit Token GitHub
• Cek Koneksi GitHub
• Kelola User Access
• System Info

Pilih aksi yang ingin dilakukan:
    `;

    const options = {
        reply_markup: {
            inline_keyboard: [
                [
                    { text: '🔑 EDIT GITHUB TOKEN', callback_data: 'edit_github_token' },
                    { text: '🌐 CHECK GITHUB', callback_data: 'check_github' }
                ],
                [
                    { text: '📊 SYSTEM INFO', callback_data: 'system_info' },
                    { text: '👥 MANAGE USERS', callback_data: 'manage_users' }
                ],
                [
                    { text: '📊 MENU UTAMA', callback_data: 'main_menu' }
                ]
            ]
        },
        parse_mode: 'HTML'
    };

    bot.sendMessage(chatId, adminText, options);
}

// Start command
bot.onText(/\/start/, async (msg) => {
    const chatId = msg.chat.id;
    const user = msg.from;
    
    console.log(`👤 User ${user.id} (${formatUserName(user)}) memulai bot`);
    
    // Setup git pertama kali
    await setupGit();
    
    showMainMenu(chatId, user);
});

// Handle callback queries (button clicks)
bot.on('callback_query', async (callbackQuery) => {
    const message = callbackQuery.message;
    const chatId = message.chat.id;
    const user = callbackQuery.from;
    const data = callbackQuery.data;

    await bot.answerCallbackQuery(callbackQuery.id);

    try {
        switch (data) {
            case 'list_ip':
                await handleListIP(chatId);
                break;
            case 'check_github':
                await handleCheckGitHub(chatId, user);
                break;
            case 'add_ip':
                await handleAddIP(chatId, user);
                break;
            case 'delete_ip':
                await handleDeleteIP(chatId, user);
                break;
            case 'renew_ip':
                await handleRenewIP(chatId, user);
                break;
            case 'sync_data':
                await handleSyncData(chatId);
                break;
            case 'refresh_bot':
                await handleRefreshBot(chatId, user);
                break;
            case 'help':
                await handleHelp(chatId, user);
                break;
            case 'main_menu':
                showMainMenu(chatId, user);
                break;
            case 'admin_settings':
                if (isAdmin(user.id.toString())) {
                    await showAdminMenu(chatId, user);
                } else {
                    await bot.sendMessage(chatId, '❌ Akses ditolak. Hanya admin yang bisa mengakses menu ini.');
                }
                break;
            case 'edit_github_token':
                if (isAdmin(user.id.toString())) {
                    await handleEditGitHubToken(chatId);
                } else {
                    await bot.sendMessage(chatId, '❌ Akses ditolak. Hanya admin yang bisa mengakses menu ini.');
                }
                break;
            case 'system_info':
                if (isAdmin(user.id.toString())) {
                    await handleSystemInfo(chatId);
                } else {
                    await bot.sendMessage(chatId, '❌ Akses ditolak. Hanya admin yang bisa mengakses menu ini.');
                }
                break;
            case 'manage_users':
                if (isAdmin(user.id.toString())) {
                    await handleManageUsers(chatId);
                } else {
                    await bot.sendMessage(chatId, '❌ Akses ditolak. Hanya admin yang bisa mengakses menu ini.');
                }
                break;
            case 'request_access':
                await handleRequestAccess(chatId, user);
                break;
            default:
                // Handle OS selection
                if (data.startsWith('add_ip_os_')) {
                    const selectedOS = data.replace('add_ip_os_', '');
                    await handleOSSelection(chatId, selectedOS, user);
                }
                // Handle delete IP selection
                else if (data.startsWith('delete_ip_')) {
                    const ipToDelete = data.replace('delete_ip_', '');
                    await handleDeleteIPSelection(chatId, ipToDelete, user);
                } else {
                    await bot.sendMessage(chatId, '❌ Aksi tidak dikenali');
                }
        }
    } catch (error) {
        console.error('❌ Callback Error:', error);
        await bot.sendMessage(chatId, '❌ Terjadi error, coba lagi nanti');
    }
});

// Handler untuk List IP
async function handleListIP(chatId) {
    try {
        const loadingMsg = await bot.sendMessage(chatId, '📋 Mengambil data IP VPS...');
        
        // Sync data dari GitHub dulu
        await loadDataFromGitHub();
        
        const ipList = formatIPList();
        
        await bot.editMessageText(ipList, {
            chat_id: chatId,
            message_id: loadingMsg.message_id,
            parse_mode: 'HTML',
            reply_markup: {
                inline_keyboard: [
                    [{ text: '🔄 Refresh', callback_data: 'list_ip' }],
                    [{ text: '📊 Menu Utama', callback_data: 'main_menu' }]
                ]
            }
        });
    } catch (error) {
        console.error('❌ List IP Error:', error);
        await bot.sendMessage(chatId, '❌ Gagal mengambil data IP VPS');
    }
}

// Handler untuk Check GitHub - DIMODIFIKASI: Hanya admin
async function handleCheckGitHub(chatId, user) {
    // Cek apakah user adalah admin
    if (!isAdmin(user.id.toString())) {
        await bot.sendMessage(chatId, '❌ Akses ditolak. Hanya admin yang bisa mengecek koneksi GitHub.', {
            reply_markup: {
                inline_keyboard: [
                    [{ text: '📊 Menu Utama', callback_data: 'main_menu' }]
                ]
            }
        });
        return;
    }

    try {
        const loadingMsg = await bot.sendMessage(chatId, '🌐 Memeriksa koneksi GitHub...');
        
        const result = await checkGitHubConnection();
        
        await bot.editMessageText(result.message, {
            chat_id: chatId,
            message_id: loadingMsg.message_id,
            parse_mode: 'HTML',
            reply_markup: {
                inline_keyboard: [
                    [{ text: '🔑 Edit Token', callback_data: 'edit_github_token' }],
                    [{ text: '🔄 Test Lagi', callback_data: 'check_github' }],
                    [{ text: '📊 Menu Utama', callback_data: 'main_menu' }]
                ]
            }
        });
    } catch (error) {
        console.error('❌ Check GitHub Error:', error);
        await bot.sendMessage(chatId, '❌ Gagal memeriksa koneksi GitHub');
    }
}

// Handler untuk Edit GitHub Token - FUNGSI BARU
async function handleEditGitHubToken(chatId) {
    const msg = await bot.sendMessage(chatId, '<b>🔑 Edit GitHub Token</b>\n\nToken saat ini: <code>' + GITHUB_TOKEN.substring(0, 8) + '...</code>\n\nMasukkan token GitHub baru:', {
        parse_mode: 'HTML',
        reply_markup: { force_reply: true }
    });

    const replyListener = async (replyMsg) => {
        if (replyMsg.reply_to_message && replyMsg.reply_to_message.message_id === msg.message_id) {
            const newToken = replyMsg.text;
            
            // Hapus listener setelah digunakan
            bot.removeListener('message', replyListener);
            
            if (newToken && newToken.length > 10) {
                const success = updateEnvVariable('GITHUB_TOKEN', newToken);
                
                if (success) {
                    await bot.sendMessage(chatId, `✅ GitHub Token berhasil diupdate!\n\nToken baru: <code>${newToken.substring(0, 8)}...</code>\n\nKlik tombol di bawah untuk test koneksi:`, {
                        parse_mode: 'HTML',
                        reply_markup: {
                            inline_keyboard: [
                                [{ text: '🌐 Test Koneksi', callback_data: 'check_github' }],
                                [{ text: '📊 Menu Utama', callback_data: 'main_menu' }]
                            ]
                        }
                    });
                } else {
                    await bot.sendMessage(chatId, '❌ Gagal mengupdate GitHub Token');
                }
            } else {
                await bot.sendMessage(chatId, '❌ Token tidak valid. Pastikan token memiliki panjang yang cukup.');
            }
        }
    };

    // Tambahkan listener untuk message
    bot.on('message', replyListener);
    
    // Set timeout untuk menghapus listener setelah 2 menit
    setTimeout(() => {
        bot.removeListener('message', replyListener);
    }, 120000);
}

// Handler untuk System Info - FUNGSI BARU
async function handleSystemInfo(chatId) {
    try {
        const loadingMsg = await bot.sendMessage(chatId, '📊 Mengambil informasi sistem...');
        
        // Dapatkan info dasar
        const nodeVersion = process.version;
        const platform = process.platform;
        const arch = process.arch;
        const uptime = Math.floor(process.uptime() / 60) + ' menit';
        
        // Hitung jumlah IP
        const ips = readIPData();
        const activeIPs = ips.filter(ip => new Date(ip.expired) > new Date()).length;
        const expiredIPs = ips.length - activeIPs;
        
        const systemInfo = `
<b>📊 SYSTEM INFORMATION</b>

<b>Bot Info:</b>
🤖 <b>Node.js Version:</b> <code>${nodeVersion}</code>
💻 <b>Platform:</b> <code>${platform} ${arch}</code>
⏰ <b>Uptime:</b> <code>${uptime}</code>

<b>GitHub Info:</b>
👤 <b>User:</b> <code>${GITHUB_USER}</code>
🔑 <b>Token:</b> <code>${GITHUB_TOKEN.substring(0, 8)}...</code>
📁 <b>Repo:</b> <code>${GITHUB_REPO}</code>

<b>Data Info:</b>
📋 <b>Total IP:</b> <code>${ips.length}</code>
✅ <b>IP Aktif:</b> <code>${activeIPs}</code>
❌ <b>IP Expired:</b> <code>${expiredIPs}</code>

<b>Server Time:</b>
🕐 ${new Date().toLocaleString('id-ID', { timeZone: 'Asia/Jakarta' })}
        `;
        
        await bot.editMessageText(systemInfo, {
            chat_id: chatId,
            message_id: loadingMsg.message_id,
            parse_mode: 'HTML',
            reply_markup: {
                inline_keyboard: [
                    [{ text: '🔄 Refresh', callback_data: 'system_info' }],
                    [{ text: '📊 Menu Utama', callback_data: 'main_menu' }]
                ]
            }
        });
    } catch (error) {
        console.error('❌ System Info Error:', error);
        await bot.sendMessage(chatId, '❌ Gagal mengambil informasi sistem');
    }
}

// Handler untuk Manage Users - FUNGSI BARU (placeholder)
async function handleManageUsers(chatId) {
    const usersData = loadAllowedUsers();
    const totalUsers = usersData.allowedUsers.length;
    const pendingRequests = usersData.pendingRequests.length;
    
    const usersInfo = `
<b>👥 USER MANAGEMENT</b>

📊 <b>Statistik:</b>
✅ <b>Total Allowed Users:</b> <code>${totalUsers}</code>
📩 <b>Pending Requests:</b> <code>${pendingRequests}</code>

⚠️ <b>Fitur dalam pengembangan</b>
Fitur manajemen user lengkap akan segera hadir!
    `;
    
    await bot.sendMessage(chatId, usersInfo, {
        parse_mode: 'HTML',
        reply_markup: {
            inline_keyboard: [
                [{ text: '📊 Menu Utama', callback_data: 'main_menu' }]
            ]
        }
    });
}

// Handler untuk Sync Data
async function handleSyncData(chatId) {
    try {
        const loadingMsg = await bot.sendMessage(chatId, '🔄 Menyinkronisasi data dengan GitHub...');
        
        const success = await loadDataFromGitHub();
        
        if (success) {
            await bot.editMessageText('✅ Data berhasil disinkronisasi dari GitHub', {
                chat_id: chatId,
                message_id: loadingMsg.message_id,
                reply_markup: {
                    inline_keyboard: [
                        [{ text: '📋 Lihat Data', callback_data: 'list_ip' }],
                        [{ text: '📊 Menu Utama', callback_data: 'main_menu' }]
                    ]
                }
            });
        } else {
            await bot.editMessageText('❌ Gagal menyinkronisasi data', {
                chat_id: chatId,
                message_id: loadingMsg.message_id
            });
        }
    } catch (error) {
        console.error('❌ Sync Data Error:', error);
        await bot.sendMessage(chatId, '❌ Gagal menyinkronisasi data');
    }
}

// Handler untuk Refresh Bot - DITAMBAH: Loading animasi spinner
async function handleRefreshBot(chatId, user) {
    try {
        // Kirim pesan loading dengan spinner
        let loadingMsg = await bot.sendMessage(chatId, '🔄 Merefresh bot...');
        
        // Animasi spinner
        const spinnerFrames = ['🔄', '⏳', '⌛', '🔄'];
        let spinnerIndex = 0;
        
        const spinnerInterval = setInterval(async () => {
            try {
                spinnerIndex = (spinnerIndex + 1) % spinnerFrames.length;
                await bot.editMessageText(`${spinnerFrames[spinnerIndex]} Merefresh bot...`, {
                    chat_id: chatId,
                    message_id: loadingMsg.message_id
                });
            } catch (error) {
                // Ignore edit errors
            }
        }, 500);
        
        // Hapus state yang aktif
        addIPState.delete(chatId);
        
        // Reload data dari GitHub
        await loadDataFromGitHub();
        
        // Hentikan animasi spinner
        clearInterval(spinnerInterval);
        
        // Update pesan menjadi sukses dengan centang
        await bot.editMessageText('✅ Bot berhasil di-refresh!', {
            chat_id: chatId,
            message_id: loadingMsg.message_id
        });
        
        // Tunggu sebentar sebelum kembali ke menu
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        // Hapus pesan loading
        await bot.deleteMessage(chatId, loadingMsg.message_id);
        
        // Langsung kembali ke menu utama
        await showMainMenu(chatId, user);
        
        console.log(`🔄 Bot di-refresh oleh user ${user.id} (${formatUserName(user)})`);
        
    } catch (error) {
        console.error('❌ Refresh Bot Error:', error);
        // Hentikan spinner jika error
        if (spinnerInterval) clearInterval(spinnerInterval);
        
        await bot.sendMessage(chatId, '❌ Gagal merefresh bot', {
            reply_markup: {
                inline_keyboard: [
                    [{ text: '📊 Menu Utama', callback_data: 'main_menu' }]
                ]
            }
        });
    }
}

// ... (fungsi-fungsi lainnya tetap sama seperti sebelumnya)
// Handler untuk Add IP - DIMODIFIKASI: Semua user wajib verifikasi password
async function handleAddIP(chatId, user) {
    await askForPassword(chatId, 'add_ip', user);
}

// Handler untuk Delete IP - DIMODIFIKASI: Semua user wajib verifikasi password
async function handleDeleteIP(chatId, user) {
    await askForPassword(chatId, 'delete_ip', user);
}

// Handler untuk Renew IP - DIMODIFIKASI: Semua user wajib verifikasi password
async function handleRenewIP(chatId, user) {
    await askForPassword(chatId, 'renew_ip', user);
}

// Handler untuk Help
async function handleHelp(chatId, user) {
    const helpText = `
<b>🆘 Bantuan VPS Manager Bot</b>

👋 Halo, <b>${formatUserName(user)}</b>!
🆔 ID Telegram: <code>${user.id}</code>
👤 Status: <b>${isAdmin(user.id.toString()) ? 'ADMIN 👑' : 'USER 👤'}</b>

<b>Cara Penggunaan:</b>
1. Gunakan button untuk memilih aksi
2. Untuk semua fitur (Add, Delete, Renew IP) wajib verifikasi password
3. Data otomatis tersinkronisasi dengan GitHub

<b>Fitur User:</b>
• <b>LIST IP</b> - Lihat semua IP VPS yang terdaftar
• <b>REFRESH BOT</b> - Refresh bot dan reset state

<b>Fitur dengan Password:</b>
• <b>ADD IP</b> - Tambah IP baru (wajib password)
• <b>DELETE IP</b> - Hapus IP (wajib password)
• <b>RENEW IP</b> - Perpanjang masa aktif IP (wajib password)

<b>Fitur Admin Only:</b>
• <b>CHECK GITHUB</b> - Test koneksi ke repository GitHub
• <b>EDIT GITHUB TOKEN</b> - Update token GitHub
• <b>SYSTEM INFO</b> - Informasi sistem bot

<b>Sistem Keamanan:</b>
- Semua aksi memerlukan verifikasi password
- Password sama untuk semua user
- Data tersinkronisasi otomatis dengan GitHub
- Fitur GitHub hanya untuk admin

👨‍💻 <b>Developer:</b> <b>PeyxDev</b>
    `;

    await bot.sendMessage(chatId, helpText, {
        parse_mode: 'HTML',
        reply_markup: {
            inline_keyboard: [
                [{ text: '📊 Menu Utama', callback_data: 'main_menu' }]
            ]
        }
    });
}

// Variabel global untuk menyimpan state proses add IP
const addIPState = new Map();

// Fungsi untuk meminta password (untuk semua user) - DIMODIFIKASI
async function askForPassword(chatId, action, user) {
    console.log(`🔐 Meminta password untuk action: ${action}, chatId: ${chatId}, user: ${user.id}`);
    
    const msg = await bot.sendMessage(chatId, '<b>🔐 Verifikasi Password</b>\n\nMasukkan password untuk melanjutkan:', {
        parse_mode: 'HTML',
        reply_markup: { force_reply: true }
    });

    const replyListener = async (replyMsg) => {
        if (replyMsg.reply_to_message && replyMsg.reply_to_message.message_id === msg.message_id) {
            const password = replyMsg.text;
            console.log(`🔑 Password diterima: ${password}`);
            
            // Hapus listener setelah digunakan
            bot.removeListener('message', replyListener);
            
            if (password === ADMIN_PASSWORD) {
                console.log('✅ Password benar, melanjutkan proses...');
                await bot.sendMessage(chatId, '✅ Password benar!');
                
                switch (action) {
                    case 'add_ip':
                        await startAddIPProcess(chatId, user);
                        break;
                    case 'delete_ip':
                        await startDeleteIPProcess(chatId);
                        break;
                    case 'renew_ip':
                        await startRenewIPProcess(chatId);
                        break;
                }
            } else {
                console.log('❌ Password salah');
                await bot.sendMessage(chatId, '❌ Password salah! Akses ditolak.', {
                    reply_markup: {
                        inline_keyboard: [
                            [{ text: '📊 Menu Utama', callback_data: 'main_menu' }]
                        ]
                    }
                });
            }
        }
    };

    // Tambahkan listener untuk message
    bot.on('message', replyListener);
    
    // Set timeout untuk menghapus listener setelah 2 menit
    setTimeout(() => {
        bot.removeListener('message', replyListener);
    }, 120000);
}

// Proses Add IP - DIMODIFIKASI
async function startAddIPProcess(chatId, user) {
    console.log('➕ Memulai proses add IP untuk chatId:', chatId);
    
    try {
        // Inisialisasi state untuk chat ini
        addIPState.set(chatId, {
            step: 'ip',
            data: {},
            userId: user.id.toString(),
            isAdmin: isAdmin(user.id.toString())
        });

        await askForIPAddress(chatId);
    } catch (error) {
        console.error('❌ Start Add IP Process Error:', error);
        await bot.sendMessage(chatId, '❌ Terjadi error saat memulai proses tambah IP');
    }
}

// Fungsi untuk meminta IP Address
async function askForIPAddress(chatId) {
    const state = addIPState.get(chatId);
    state.step = 'ip';
    
    const msg = await bot.sendMessage(chatId, '<b>➕ Tambah IP VPS</b>\n\nMasukkan IP Address:', {
        parse_mode: 'HTML',
        reply_markup: { force_reply: true }
    });

    const replyListener = async (replyMsg) => {
        if (replyMsg.reply_to_message && replyMsg.reply_to_message.message_id === msg.message_id) {
            const ipAddress = replyMsg.text;
            
            // Hapus listener
            bot.removeListener('message', replyListener);
            
            console.log('🌐 IP Address diterima:', ipAddress);
            state.data.ip = ipAddress;
            addIPState.set(chatId, state);
            
            await askForUsername(chatId);
        }
    };

    bot.on('message', replyListener);
    
    // Timeout
    setTimeout(() => {
        bot.removeListener('message', replyListener);
    }, 120000);
}

// Fungsi untuk meminta Username
async function askForUsername(chatId) {
    const state = addIPState.get(chatId);
    state.step = 'username';
    
    const msg = await bot.sendMessage(chatId, 'Masukkan Username:', {
        reply_markup: { force_reply: true }
    });

    const replyListener = async (replyMsg) => {
        if (replyMsg.reply_to_message && replyMsg.reply_to_message.message_id === msg.message_id) {
            const username = replyMsg.text;
            
            // Hapus listener
            bot.removeListener('message', replyListener);
            
            console.log('👤 Username diterima:', username);
            state.data.username = username;
            addIPState.set(chatId, state);
            
            await askForDays(chatId);
        }
    };

    bot.on('message', replyListener);
    
    // Timeout
    setTimeout(() => {
        bot.removeListener('message', replyListener);
    }, 120000);
}

// Fungsi untuk meminta Days
async function askForDays(chatId) {
    const state = addIPState.get(chatId);
    state.step = 'days';
    
    const msg = await bot.sendMessage(chatId, 'Masukkan masa aktif (hari):', {
        reply_markup: { force_reply: true }
    });

    const replyListener = async (replyMsg) => {
        if (replyMsg.reply_to_message && replyMsg.reply_to_message.message_id === msg.message_id) {
            const days = replyMsg.text;
            
            // Hapus listener
            bot.removeListener('message', replyListener);
            
            console.log('⏰ Days diterima:', days);
            state.data.days = days;
            addIPState.set(chatId, state);
            
            await askForOS(chatId);
        }
    };

    bot.on('message', replyListener);
    
    // Timeout
    setTimeout(() => {
        bot.removeListener('message', replyListener);
    }, 120000);
}

// Fungsi untuk meminta OS
async function askForOS(chatId) {
    const state = addIPState.get(chatId);
    state.step = 'os';
    
    await bot.sendMessage(chatId, 'Pilih OS VPS:', {
        reply_markup: {
            inline_keyboard: [
                [
                    { text: '🟠 Ubuntu', callback_data: 'add_ip_os_ubuntu' },
                    { text: '🔴 Debian', callback_data: 'add_ip_os_debian' }
                ]
            ]
        }
    });
}

// Handler untuk OS selection - DIMODIFIKASI
async function handleOSSelection(chatId, osType, user) {
    console.log('🐧 OS dipilih:', osType, 'untuk chatId:', chatId);
    
    const state = addIPState.get(chatId);
    if (!state) {
        await bot.sendMessage(chatId, '❌ Sesi telah berakhir. Silakan mulai ulang.');
        return;
    }
    
    state.data.os = osType;
    
    const loadingMsg = await bot.sendMessage(chatId, '⏳ Menambahkan IP VPS...');
    
    try {
        const { ip, username, days, os } = state.data;
        const userId = state.userId;
        
        console.log('📝 Data untuk add IP:', { ip, username, days, os, userId });
        
        const expiredDate = addIP(username, ip, days);
        const saved = await saveDataToGitHub(`Add IP ${ip} oleh ${userId}`);
        
        if (saved) {
            // Hapus state
            addIPState.delete(chatId);
            
            // Kirim konfirmasi sukses
            await bot.editMessageText(`<b>✅ IP VPS Berhasil Ditambahkan!</b>\n\n📝 <b>Username:</b> ${username}\n🌐 <b>IP:</b> ${ip}\n📅 <b>Expired:</b> ${expiredDate}\n⏰ <b>Masa Aktif:</b> ${days} hari\n🐧 <b>OS:</b> ${os === 'ubuntu' ? 'Ubuntu' : 'Debian'}`, {
                chat_id: chatId,
                message_id: loadingMsg.message_id,
                parse_mode: 'HTML'
            });

            // Kirim script install
            const installScript = generateInstallScript(os, ip, username);
            await bot.sendMessage(chatId, installScript, {
                parse_mode: 'HTML',
                reply_markup: {
                    inline_keyboard: [
                        [{ text: '📋 Lihat Semua IP', callback_data: 'list_ip' }],
                        [{ text: '📊 Menu Utama', callback_data: 'main_menu' }]
                    ]
                }
            });
            
            console.log(`✅ IP ${ip} berhasil ditambahkan oleh user ${userId}`);
        } else {
            throw new Error('Gagal menyimpan ke GitHub');
        }
    } catch (error) {
        console.error('❌ Add IP Error:', error);
        await bot.editMessageText('❌ Gagal menambahkan IP VPS', {
            chat_id: chatId,
            message_id: loadingMsg.message_id
        });
        
        // Hapus state jika error
        addIPState.delete(chatId);
    }
}

// Proses Delete IP - DIMODIFIKASI
async function startDeleteIPProcess(chatId) {
    console.log('🗑️ Memulai proses delete IP untuk chatId:', chatId);
    
    try {
        // Load data terbaru dari GitHub
        await loadDataFromGitHub();
        
        const ips = readIPData();
        if (ips.length === 0) {
            await bot.sendMessage(chatId, '❌ Tidak ada IP VPS yang bisa dihapus');
            return;
        }
        
        // Buat keyboard dengan daftar IP
        const keyboard = [];
        ips.forEach(ipData => {
            keyboard.push([{ 
                text: `🗑️ ${ipData.ip} (${ipData.username})`, 
                callback_data: `delete_ip_${ipData.ip}` 
            }]);
        });
        
        keyboard.push([{ text: '❌ Batal', callback_data: 'main_menu' }]);
        
        await bot.sendMessage(chatId, '🗑️ <b>Hapus IP VPS</b>\n\nPilih IP yang ingin dihapus:', {
            parse_mode: 'HTML',
            reply_markup: {
                inline_keyboard: keyboard
            }
        });
    } catch (error) {
        console.error('❌ Start Delete IP Process Error:', error);
        await bot.sendMessage(chatId, '❌ Terjadi error saat memulai proses hapus IP');
    }
}

// Handler untuk delete IP selection
async function handleDeleteIPSelection(chatId, ipToDelete, user) {
    try {
        const loadingMsg = await bot.sendMessage(chatId, '⏳ Menghapus IP VPS...');
        
        const deleted = deleteIP(ipToDelete);
        
        if (deleted) {
            const saved = await saveDataToGitHub(`Delete IP ${ipToDelete} oleh ${user.id}`);
            
            if (saved) {
                await bot.editMessageText(`<b>✅ IP VPS Berhasil Dihapus!</b>\n\n🌐 <b>IP:</b> ${ipToDelete}`, {
                    chat_id: chatId,
                    message_id: loadingMsg.message_id,
                    parse_mode: 'HTML',
                    reply_markup: {
                        inline_keyboard: [
                            [{ text: '📋 Lihat Data', callback_data: 'list_ip' }],
                            [{ text: '📊 Menu Utama', callback_data: 'main_menu' }]
                        ]
                    }
                });
                
                console.log(`✅ IP ${ipToDelete} berhasil dihapus oleh user ${user.id}`);
            } else {
                throw new Error('Gagal menyimpan ke GitHub');
            }
        } else {
            await bot.editMessageText('❌ IP tidak ditemukan', {
                chat_id: chatId,
                message_id: loadingMsg.message_id
            });
        }
    } catch (error) {
        console.error('❌ Delete IP Error:', error);
        await bot.editMessageText('❌ Gagal menghapus IP VPS', {
            chat_id: chatId,
            message_id: loadingMsg.message_id
        });
    }
}

// Proses Renew IP - DIMODIFIKASI
async function startRenewIPProcess(chatId) {
    console.log('🔄 Memulai proses renew IP untuk chatId:', chatId);
    
    try {
        // Load data terbaru dari GitHub
        await loadDataFromGitHub();
        
        const ips = readIPData();
        if (ips.length === 0) {
            await bot.sendMessage(chatId, '❌ Tidak ada IP VPS yang bisa diperpanjang');
            return;
        }
        
        // Buat keyboard dengan daftar IP
        const keyboard = [];
        ips.forEach(ipData => {
            keyboard.push([{ 
                text: `🔄 ${ipData.ip} (${ipData.username})`, 
                callback_data: `renew_ip_${ipData.ip}` 
            }]);
        });
        
        keyboard.push([{ text: '❌ Batal', callback_data: 'main_menu' }]);
        
        await bot.sendMessage(chatId, '🔄 <b>Perpanjang IP VPS</b>\n\nPilih IP yang ingin diperpanjang:', {
            parse_mode: 'HTML',
            reply_markup: {
                inline_keyboard: keyboard
            }
        });
    } catch (error) {
        console.error('❌ Start Renew IP Process Error:', error);
        await bot.sendMessage(chatId, '❌ Terjadi error saat memulai proses perpanjang IP');
    }
}

// Handler untuk request access (jika diperlukan)
async function handleRequestAccess(chatId, user) {
    const usersData = loadAllowedUsers();
    const userName = formatUserName(user);
    
    // Tambah ke pending requests
    usersData.pendingRequests.push({
        userId: user.id.toString(),
        userName: userName,
        timestamp: Date.now()
    });
    
    saveAllowedUsers(usersData);
    
    // Kirim notifikasi ke admin
    const adminMessage = `📩 <b>Request Akses Baru</b>\n\n👤 <b>User:</b> ${userName}\n🆔 <b>ID:</b> <code>${user.id}</code>\n⏰ <b>Waktu:</b> ${new Date().toLocaleString('id-ID')}`;
    
    await bot.sendMessage(ADMIN_CHAT_ID, adminMessage, {
        parse_mode: 'HTML'
    });
    
    await bot.sendMessage(chatId, '✅ Request akses telah dikirim ke admin. Tunggu konfirmasi.', {
        reply_markup: {
            inline_keyboard: [
                [{ text: '📊 Menu Utama', callback_data: 'main_menu' }]
            ]
        }
    });
}

// Error handling
bot.on('error', (error) => {
    console.error('❌ Bot Error:', error);
});

bot.on('polling_error', (error) => {
    console.error('❌ Polling Error:', error);
});

console.log('✅ Bot berhasil diinisialisasi');