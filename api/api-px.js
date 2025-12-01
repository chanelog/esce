const express = require("express");
const { exec } = require("child_process");
const app = express();
const PORT = 5888;

// Middleware untuk parsing query string
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// Base path untuk eksekusi command (sesuai dengan Python)
const BASE_PATH = "/usr/bin/";

// AUTH_KEY - Gunakan environment variable atau fallback ke default
const AUTH_KEY = process.env.AUTH_KEY || "DEFAULT_AUTH_KEY_12345";

// Jika tidak ada AUTH_KEY di environment, gunakan default
if (!process.env.AUTH_KEY) {
    console.warn("⚠️  AUTH_KEY not set in environment, using default key");
}

console.log(`🔑 AUTH_KEY: ${AUTH_KEY ? '***' + AUTH_KEY.slice(-4) : 'NOT SET'}`);

// Environment untuk subprocess
const PROCESS_ENV = {
    ...process.env,
    TERM: "xterm-256color",
    PATH: "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    LANG: "en_US.UTF-8",
    LC_ALL: "en_US.UTF-8"
};

// Fungsi untuk parsing output shell ke JSON
function parseSSHOutput(output) {
    const extract = (pattern) => {
        const match = output.match(pattern);
        return match ? match[1].trim() : "";
    };

    return {
        username: extract(/Remark\s+:\s+(\S+)/) || extract(/Username\s+:\s+(\S+)/) || extract(/Client Name\s+:\s+(\S+)/),
        password: extract(/Password\s+:\s+(\S+)/),
        ip_limit: extract(/Limit Ip\s+:\s+(.+)/) || extract(/Limit IP\s+:\s+(.+)/),
        domain: extract(/Domain\s+:\s+(\S+)/),
        ns_domain: extract(/Ns Domain\s+:\s+(.+)/),
        pubkey: extract(/Pub Key\s+:\s+(.+)/),
        isp: extract(/ISP\s+:\s+(.+)/),
        expired: extract(/Expiry in\s+:\s+(.+)/) || extract(/Expired\s+:\s+(.+)/) || extract(/Expired On\s+:\s+(.+)/),
        uuid: extract(/Key\s+:\s+(.+)/) || extract(/UUID\s+:\s+(.+)/),
        quota: extract(/Limit Quota\s+:\s+(.+)/) || extract(/Quota\s+:\s+(.+)/),
        vmess_tls_link: extract(/Link TLS\s+:\s+(.+)/),
        vmess_nontls_link: extract(/Link WS\s+:\s+(.+)/),
        vmess_grpc_link: extract(/Link GRPC\s+:\s+(.+)/),
        vless_tls_link: extract(/Link TLS\s+:\s+(.+)/),
        vless_nontls_link: extract(/Link WS\s+:\s+(.+)/),
        vless_grpc_link: extract(/Link GRPC\s+:\s+(.+)/),
        trojan_tls_link: extract(/Link TLS\s+:\s+(.+)/),
        trojan_nontls_link: extract(/Link WS\s+:\s+(.+)/),
        trojan_grpc_link: extract(/Link GRPC\s+:\s+(.+)/),
        ss_link_nontls: extract(/Link WS\s+:\s+(.+)/),
        ss_link_ws: extract(/Link TLS\s+:\s+(.+)/),
        ss_link_grpc: extract(/Link GRPC\s+:\s+(.+)/),
    };
}

// ========================= HELPER FUNCTIONS =========================

function validateAuth(auth, res) {
    if (!AUTH_KEY) {
        res.status(500).json({ status: "error", message: "AUTH_KEY not set" });
        return false;
    }

    if (auth !== AUTH_KEY) {
        res.status(403).json({ status: "error", message: "Unauthorized" });
        return false;
    }

    return true;
}

function handleExecResult(error, stdout, stderr, res, serviceName) {
    if (error) {
        console.error(`❌ ${serviceName} Error:`, stderr || error.message);
        return res.json({ 
            status: "error", 
            message: stderr || error.message || `Gagal melakukan operasi ${serviceName}` 
        });
    }

    // Parsing output shell menjadi JSON
    const data = parseSSHOutput(stdout);

    res.json({
        status: "success",
        message: `${serviceName} berhasil`,
        data: data
    });
}

function executeCommand(cmd, res, serviceName) {
    exec(cmd, { env: PROCESS_ENV, timeout: 30000 }, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, serviceName);
    });
}

// ========================= SSH ENDPOINTS =========================

// CREATE SSH
app.get("/createssh", (req, res) => {
    const { user, password, exp, iplimit, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user || !password || !exp || !iplimit) {
        return res.status(400).json({ status: "error", message: "Missing parameters" });
    }

    const cmd = `printf "%s\\n" "${user}" "${password}" "${iplimit}" "${exp}" | ${BASE_PATH}bot-add-ssh`;
    executeCommand(cmd, res, "SSH");
});

// TRIAL SSH
app.get("/trialssh", (req, res) => {
    const { user, exp, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    const username = user || `trial${Math.floor(1000 + Math.random() * 9000)}`;
    const duration = exp || "60";
    
    const cmd = `printf "%s\\n" "${username}" "${duration}" | ${BASE_PATH}bot-trial-ssh`;
    executeCommand(cmd, res, "Trial SSH");
});

// RENEW SSH
app.get("/renewssh", (req, res) => {
    const { user, exp, iplimit, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user || !exp || !iplimit) {
        return res.status(400).json({ status: "error", message: "Missing parameters" });
    }

    const cmd = `printf "%s\\n" "${user}" "${iplimit}" "${exp}" | ${BASE_PATH}bot-renew-ssh`;
    executeCommand(cmd, res, "Renew SSH");
});

// DELETE SSH
app.get("/deletessh", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-del-ssh`;
    
    exec(cmd, { env: PROCESS_ENV, timeout: 30000 }, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal menghapus akun SSH" });
        }
        res.json({
            status: "success",
            message: `Akun SSH ${user} berhasil dihapus`,
            data: { username: user }
        });
    });
});

// LOCK SSH
app.get("/lockssh", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-lock`;
    
    exec(cmd, { env: PROCESS_ENV, timeout: 30000 }, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal meng-lock akun SSH" });
        }
        res.json({
            status: "success",
            message: `Akun SSH ${user} berhasil di-lock`,
            data: { username: user }
        });
    });
});

// UNLOCK SSH
app.get("/unlockssh", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-unlock`;
    
    exec(cmd, { env: PROCESS_ENV, timeout: 30000 }, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal meng-unlock akun SSH" });
        }
        res.json({
            status: "success",
            message: `Akun SSH ${user} berhasil di-unlock`,
            data: { username: user }
        });
    });
});

// LIMIT IP SSH
app.get("/limitssh", (req, res) => {
    const { user, iplimit, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user || !iplimit) {
        return res.status(400).json({ status: "error", message: "Missing parameters" });
    }

    const cmd = `printf "%s\\n" "${user}" "${iplimit}" | ${BASE_PATH}bot-ganti-ip-ssh`;
    executeCommand(cmd, res, "Limit IP SSH");
});

// RECOVER/DETAIL SSH
app.get("/recoverssh", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-user-ssh`;
    executeCommand(cmd, res, "Detail SSH");
});

// SHOW ALL SSH USERS
app.get("/showssh", (req, res) => {
    const { auth } = req.query;

    if (!validateAuth(auth, res)) return;

    const cmd = `${BASE_PATH}bot-member-ssh`;
    
    exec(cmd, { env: PROCESS_ENV, timeout: 30000 }, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal mengambil data user SSH" });
        }
        res.json({
            status: "success",
            message: "Data user SSH berhasil diambil",
            data: { output: stdout }
        });
    });
});

// CHECK LOGIN SSH
app.get("/loginssh", (req, res) => {
    const { auth } = req.query;

    if (!validateAuth(auth, res)) return;

    const cmd = `${BASE_PATH}bot-cek-login-ssh`;
    
    exec(cmd, { env: PROCESS_ENV, timeout: 30000 }, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal memeriksa login SSH" });
        }
        res.json({
            status: "success",
            message: "Data login SSH berhasil diambil",
            data: { output: stdout }
        });
    });
});

// ========================= VMESS ENDPOINTS =========================

// CREATE VMESS
app.get("/createvmess", (req, res) => {
    const { user, exp, iplimit, quota, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user || !exp || !quota || !iplimit) {
        return res.status(400).json({ status: "error", message: "Missing parameters" });
    }

    const uuid = require('crypto').randomUUID ? require('crypto').randomUUID() : require('uuid').v4();
    
    const cmd = `printf "%s\\n" "${user}" "${uuid}" "${quota}" "${iplimit}" "${exp}" | ${BASE_PATH}bot-add-vme`;
    executeCommand(cmd, res, "VMESS");
});

// TRIAL VMESS
app.get("/trialvmess", (req, res) => {
    const { user, exp, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    const username = user || `trial${Math.floor(1000 + Math.random() * 9000)}`;
    const duration = exp || "60";
    
    const cmd = `printf "%s\\n" "${username}" "${duration}" | ${BASE_PATH}bot-trial-vme`;
    executeCommand(cmd, res, "Trial VMESS");
});

// RENEW VMESS
app.get("/renewvmess", (req, res) => {
    const { user, exp, iplimit, quota, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user || !exp || !iplimit || !quota) {
        return res.status(400).json({ status: "error", message: "Missing parameters" });
    }

    const cmd = `printf "%s\\n" "${user}" "${exp}" "${quota}" "${iplimit}" | ${BASE_PATH}bot-renew-vme`;
    executeCommand(cmd, res, "Renew VMESS");
});

// DELETE VMESS
app.get("/deletevmess", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-del-vme`;
    
    exec(cmd, { env: PROCESS_ENV, timeout: 30000 }, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal menghapus akun VMESS" });
        }
        res.json({
            status: "success",
            message: `Akun VMESS ${user} berhasil dihapus`,
            data: { username: user }
        });
    });
});

// LOCK VMESS
app.get("/lockvmess", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-lock-vm`;
    
    exec(cmd, { env: PROCESS_ENV, timeout: 30000 }, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal meng-lock akun VMESS" });
        }
        res.json({
            status: "success",
            message: `Akun VMESS ${user} berhasil di-lock`,
            data: { username: user }
        });
    });
});

// UNLOCK VMESS
app.get("/unlockvmess", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-unlock-vm`;
    
    exec(cmd, { env: PROCESS_ENV, timeout: 30000 }, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal meng-unlock akun VMESS" });
        }
        res.json({
            status: "success",
            message: `Akun VMESS ${user} berhasil di-unlock`,
            data: { username: user }
        });
    });
});

// LIMIT IP VMESS
app.get("/limitvmess", (req, res) => {
    const { user, iplimit, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user || !iplimit) {
        return res.status(400).json({ status: "error", message: "Missing parameters" });
    }

    const cmd = `printf "%s\\n" "${user}" "${iplimit}" | ${BASE_PATH}bot-ganti-ip-vmess`;
    executeCommand(cmd, res, "Limit IP VMESS");
});

// RECOVER/DETAIL VMESS
app.get("/recovervmess", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-recover-vm`;
    executeCommand(cmd, res, "Detail VMESS");
});

// SHOW ALL VMESS USERS
app.get("/showvmess", (req, res) => {
    const { auth } = req.query;

    if (!validateAuth(auth, res)) return;

    const cmd = `${BASE_PATH}bot-member-vme`;
    
    exec(cmd, { env: PROCESS_ENV, timeout: 30000 }, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal mengambil data user VMESS" });
        }
        res.json({
            status: "success",
            message: "Data user VMESS berhasil diambil",
            data: { output: stdout }
        });
    });
});

// CHECK LOGIN VMESS
app.get("/loginvmess", (req, res) => {
    const { auth } = req.query;

    if (!validateAuth(auth, res)) return;

    const cmd = `${BASE_PATH}bot-cek-ws`;
    
    exec(cmd, { env: PROCESS_ENV, timeout: 30000 }, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal memeriksa login VMESS" });
        }
        res.json({
            status: "success",
            message: "Data login VMESS berhasil diambil",
            data: { output: stdout }
        });
    });
});

// ========================= HEALTH CHECK =========================

app.get("/", (req, res) => {
    res.json({
        status: "success",
        message: "API-PX is running",
        version: "1.0.0",
        timestamp: new Date().toISOString()
    });
});

app.get("/health", (req, res) => {
    res.json({
        status: "success",
        message: "API is healthy",
        environment: {
            node_version: process.version,
            platform: process.platform,
            auth_key_set: !!AUTH_KEY
        }
    });
});

// ========================= ERROR HANDLING =========================

app.use((req, res) => {
    res.status(404).json({
        status: "error",
        message: "Endpoint not found"
    });
});

app.use((error, req, res, next) => {
    console.error("❌ Server Error:", error);
    res.status(500).json({
        status: "error",
        message: "Internal server error"
    });
});

// ========================= START SERVER =========================

app.listen(PORT, "0.0.0.0", () => {
    console.log(`🚀 Server API berjalan di port ${PORT}`);
    console.log(`🔑 AUTH_KEY: ${AUTH_KEY ? '***' + AUTH_KEY.slice(-4) : 'NOT SET'}`);
    console.log(`📁 Base path: ${BASE_PATH}`);
    console.log(`🌐 Environment: ${JSON.stringify(PROCESS_ENV, null, 2)}`);
    console.log(`📋 Available endpoints:`);
    console.log(`- SSH: /createssh, /trialssh, /renewssh, /deletessh, /lockssh, /unlockssh, /limitssh, /recoverssh, /showssh, /loginssh`);
    console.log(`- VMESS: /createvmess, /trialvmess, /renewvmess, /deletevmess, /lockvmess, /unlockvmess, /limitvmess, /recovervmess, /showvmess, /loginvmess`);
    console.log(`- Health: /, /health`);
});