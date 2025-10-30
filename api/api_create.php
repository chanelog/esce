<?php
// api-create-account.php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// API Key untuk keamanan (ganti dengan key yang kuat)
$valid_api_key = 'PX_STORE_2025';

// Validasi API Key
$headers = getallheaders();
$provided_api_key = isset($headers['Authorization']) ? str_replace('Bearer ', '', $headers['Authorization']) : '';

if ($provided_api_key !== $valid_api_key) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized: Invalid API Key']);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        
        // Validasi input
        if (!isset($input['username']) || !isset($input['password']) || !isset($input['package']) || !isset($input['service_type'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Data tidak lengkap: username, password, package, dan service_type diperlukan']);
            exit();
        }
        
        $username = trim($input['username']);
        $password = trim($input['password']);
        $package = trim($input['package']);
        $service_type = trim($input['service_type']); // ssh, vmess, vless, trojan
        
        // Validasi format username (hanya huruf dan angka)
        if (!preg_match('/^[a-zA-Z0-9]+$/', $username)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Username hanya boleh mengandung huruf dan angka']);
            exit();
        }
        
        // Validasi panjang password
        if (strlen($password) < 4) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Password minimal 4 karakter']);
            exit();
        }
        
        // Validasi service type
        $allowed_services = ['ssh', 'vmess', 'vless', 'trojan'];
        if (!in_array($service_type, $allowed_services)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Service type tidak valid']);
            exit();
        }
        
        // Escape input untuk keamanan
        $escaped_username = escapeshellarg($username);
        $escaped_password = escapeshellarg($password);
        $escaped_package = escapeshellarg($package);
        
        // Tentukan command berdasarkan service type
        $command = '';
        switch($service_type) {
            case 'ssh':
                $command = "sudo /usr/local/sbin/addssh {$escaped_username} {$escaped_password} {$escaped_package}";
                break;
            case 'vmess':
                $command = "sudo /usr/local/sbin/add-vme {$escaped_username} {$escaped_password} {$escaped_package}";
                break;
            case 'vless':
                $command = "sudo /usr/local/sbin/add-vle {$escaped_username} {$escaped_password} {$escaped_package}";
                break;
            case 'trojan':
                $command = "sudo /usr/local/sbin/add-tro {$escaped_username} {$escaped_password} {$escaped_package}";
                break;
            default:
                throw new Exception('Service type tidak dikenali');
        }
        
        // Eksekusi command
        $output = shell_exec($command . " 2>&1");
        
        // Log hasil eksekusi
        $log_message = date('Y-m-d H:i:s') . " - {$service_type} - {$username} - {$package} - {$output}\n";
        file_put_contents('/tmp/vpn_creation.log', $log_message, FILE_APPEND);
        
        // Cek hasil eksekusi berdasarkan service type
        $success_patterns = [
            'ssh' => ['berhasil', 'success', 'created', 'Adding', 'added'],
            'vmess' => ['berhasil', 'success', 'created', 'Adding', 'added', 'vmess'],
            'vless' => ['berhasil', 'success', 'created', 'Adding', 'added', 'vless'],
            'trojan' => ['berhasil', 'success', 'created', 'Adding', 'added', 'trojan']
        ];
        
        $is_success = false;
        if (isset($success_patterns[$service_type])) {
            foreach ($success_patterns[$service_type] as $pattern) {
                if (stripos($output, $pattern) !== false) {
                    $is_success = true;
                    break;
                }
            }
        }
        
        if ($is_success) {
            // Parse output untuk mendapatkan detail akun
            $account_details = parseAccountOutput($service_type, $output, $username, $password);
            
            echo json_encode([
                'success' => true, 
                'message' => "Akun {$service_type} berhasil dibuat",
                'data' => [
                    'username' => $username,
                    'password' => $password,
                    'package' => $package,
                    'service_type' => $service_type,
                    'server' => 'ID NEVA',
                    'created_at' => date('Y-m-d H:i:s'),
                    'details' => $account_details
                ],
                'output' => trim($output)
            ]);
            
        } else {
            http_response_code(500);
            echo json_encode([
                'success' => false, 
                'message' => "Gagal membuat akun {$service_type}",
                'error' => trim($output)
            ]);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false, 
            'message' => 'Terjadi kesalahan sistem',
            'error' => $e->getMessage()
        ]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method tidak diizinkan']);
}

// Fungsi untuk parsing output dan ekstrak detail akun
function parseAccountOutput($service_type, $output, $username, $password) {
    $details = [
        'username' => $username,
        'password' => $password,
        'server' => 'your-server-domain.com',
        'port' => '',
        'method' => '',
        'protocol' => '',
        'link' => ''
    ];
    
    switch($service_type) {
        case 'ssh':
            $details['port'] = '22';
            $details['method'] = 'chacha20-poly1305';
            $details['protocol'] = 'SSH';
            break;
            
        case 'vmess':
            // Parse VMess output untuk mendapatkan port dan UUID
            if (preg_match('/port[\s:]*(\d+)/i', $output, $matches)) {
                $details['port'] = $matches[1];
            } else {
                $details['port'] = '443';
            }
            
            if (preg_match('/uuid[\s:]*([a-f0-9-]+)/i', $output, $matches)) {
                $details['uuid'] = $matches[1];
            }
            
            $details['method'] = 'auto';
            $details['protocol'] = 'VMess';
            $details['link'] = generateVmessLink($details);
            break;
            
        case 'vless':
            if (preg_match('/port[\s:]*(\d+)/i', $output, $matches)) {
                $details['port'] = $matches[1];
            } else {
                $details['port'] = '443';
            }
            
            if (preg_match('/uuid[\s:]*([a-f0-9-]+)/i', $output, $matches)) {
                $details['uuid'] = $matches[1];
            }
            
            $details['method'] = 'none';
            $details['protocol'] = 'VLESS';
            $details['link'] = generateVlessLink($details);
            break;
            
        case 'trojan':
            if (preg_match('/port[\s:]*(\d+)/i', $output, $matches)) {
                $details['port'] = $matches[1];
            } else {
                $details['port'] = '443';
            }
            
            $details['method'] = 'trojan';
            $details['protocol'] = 'Trojan';
            $details['link'] = generateTrojanLink($details);
            break;
    }
    
    return $details;
}

// Fungsi generate link konfigurasi
function generateVmessLink($details) {
    $config = [
        "v" => "2",
        "ps" => "PX-STORE-{$details['username']}",
        "add" => $details['server'],
        "port" => $details['port'],
        "id" => $details['uuid'] ?? $details['password'],
        "aid" => "0",
        "scy" => "auto",
        "net" => "ws",
        "type" => "none",
        "host" => "",
        "path" => "/vmess",
        "tls" => "tls",
        "sni" => ""
    ];
    
    return "vmess://" . base64_encode(json_encode($config));
}

function generateVlessLink($details) {
    $uuid = $details['uuid'] ?? $details['password'];
    return "vless://{$uuid}@{$details['server']}:{$details['port']}?encryption=none&security=tls&type=ws&path=%2Fvless#PX-STORE-{$details['username']}";
}

function generateTrojanLink($details) {
    return "trojan://{$details['password']}@{$details['server']}:{$details['port']}?security=tls&type=ws&path=%2Ftrojan#PX-STORE-{$details['username']}";
}
?>