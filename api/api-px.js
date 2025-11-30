const express = require("express");
const { exec } = require("child_process");
const app = express();
const PORT = 5888;

// Middleware untuk parsing query string
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// Base path untuk eksekusi command (sesuai dengan Python)
const BASE_PATH = "/usr/bin/";

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

const AUTH_KEY = process.env.AUTH_KEY;

// ========================= SSH ENDPOINTS =========================

// CREATE SSH
app.get("/createssh", (req, res) => {
    const { user, password, exp, iplimit, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user || !password || !exp || !iplimit) {
        return res.status(400).json({ status: "error", message: "Missing parameters" });
    }

    const cmd = `printf "%s\\n" "${user}" "${password}" "${iplimit}" "${exp}" | ${BASE_PATH}bot-add-ssh`;

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "SSH");
    });
});

// TRIAL SSH
app.get("/trialssh", (req, res) => {
    const { user, exp, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    const username = user || `trial${Math.floor(1000 + Math.random() * 9000)}`;
    const duration = exp || "60";
    
    const cmd = `printf "%s\\n" "${username}" "${duration}" | ${BASE_PATH}bot-trial-ssh`;

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "Trial SSH");
    });
});

// RENEW SSH
app.get("/renewssh", (req, res) => {
    const { user, exp, iplimit, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user || !exp || !iplimit) {
        return res.status(400).json({ status: "error", message: "Missing parameters" });
    }

    const cmd = `printf "%s\\n" "${user}" "${iplimit}" "${exp}" | ${BASE_PATH}bot-renew-ssh`;

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "Renew SSH");
    });
});

// DELETE SSH
app.get("/deletessh", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-del-ssh`;

    exec(cmd, (error, stdout, stderr) => {
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

    exec(cmd, (error, stdout, stderr) => {
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

    exec(cmd, (error, stdout, stderr) => {
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

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "Limit IP SSH");
    });
});

// RECOVER/DETAIL SSH
app.get("/recoverssh", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-user-ssh`;

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "Detail SSH");
    });
});

// SHOW ALL SSH USERS
app.get("/showssh", (req, res) => {
    const { auth } = req.query;

    if (!validateAuth(auth, res)) return;

    const cmd = `${BASE_PATH}bot-member-ssh`;

    exec(cmd, (error, stdout, stderr) => {
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

    exec(cmd, (error, stdout, stderr) => {
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

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "VMESS");
    });
});

// TRIAL VMESS
app.get("/trialvmess", (req, res) => {
    const { user, exp, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    const username = user || `trial${Math.floor(1000 + Math.random() * 9000)}`;
    const duration = exp || "60";
    
    const cmd = `printf "%s\\n" "${username}" "${duration}" | ${BASE_PATH}bot-trial-vme`;

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "Trial VMESS");
    });
});

// RENEW VMESS
app.get("/renewvmess", (req, res) => {
    const { user, exp, iplimit, quota, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user || !exp || !iplimit || !quota) {
        return res.status(400).json({ status: "error", message: "Missing parameters" });
    }

    const cmd = `printf "%s\\n" "${user}" "${exp}" "${quota}" "${iplimit}" | ${BASE_PATH}bot-renew-vme`;

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "Renew VMESS");
    });
});

// DELETE VMESS
app.get("/deletevmess", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-del-vme`;

    exec(cmd, (error, stdout, stderr) => {
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

    exec(cmd, (error, stdout, stderr) => {
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

    exec(cmd, (error, stdout, stderr) => {
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

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "Limit IP VMESS");
    });
});

// RECOVER/DETAIL VMESS
app.get("/recovervmess", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-recover-vm`;

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "Detail VMESS");
    });
});

// SHOW ALL VMESS USERS
app.get("/showvmess", (req, res) => {
    const { auth } = req.query;

    if (!validateAuth(auth, res)) return;

    const cmd = `${BASE_PATH}bot-member-vme`;

    exec(cmd, (error, stdout, stderr) => {
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

    exec(cmd, (error, stdout, stderr) => {
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

// ========================= VLESS ENDPOINTS =========================

// CREATE VLESS
app.get("/createvless", (req, res) => {
    const { user, exp, iplimit, quota, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user || !exp || !quota || !iplimit) {
        return res.status(400).json({ status: "error", message: "Missing parameters" });
    }

    const uuid = require('crypto').randomUUID ? require('crypto').randomUUID() : require('uuid').v4();
    
    const cmd = `printf "%s\\n" "${user}" "${uuid}" "${quota}" "${iplimit}" "${exp}" | ${BASE_PATH}bot-add-vle`;

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "VLESS");
    });
});

// TRIAL VLESS
app.get("/trialvless", (req, res) => {
    const { user, exp, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    const username = user || `trial${Math.floor(1000 + Math.random() * 9000)}`;
    const duration = exp || "60";
    
    const cmd = `printf "%s\\n" "${username}" "${duration}" | ${BASE_PATH}bot-trial-vle`;

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "Trial VLESS");
    });
});

// RENEW VLESS
app.get("/renewvless", (req, res) => {
    const { user, exp, iplimit, quota, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user || !exp || !iplimit || !quota) {
        return res.status(400).json({ status: "error", message: "Missing parameters" });
    }

    const cmd = `printf "%s\\n" "${user}" "${exp}" "${quota}" "${iplimit}" | ${BASE_PATH}bot-renew-vle`;

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "Renew VLESS");
    });
});

// DELETE VLESS
app.get("/deletevless", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-del-vle`;

    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal menghapus akun VLESS" });
        }
        res.json({
            status: "success",
            message: `Akun VLESS ${user} berhasil dihapus`,
            data: { username: user }
        });
    });
});

// LOCK VLESS
app.get("/lockvless", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-lock-vl`;

    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal meng-lock akun VLESS" });
        }
        res.json({
            status: "success",
            message: `Akun VLESS ${user} berhasil di-lock`,
            data: { username: user }
        });
    });
});

// UNLOCK VLESS
app.get("/unlockvless", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-unlock-vl`;

    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal meng-unlock akun VLESS" });
        }
        res.json({
            status: "success",
            message: `Akun VLESS ${user} berhasil di-unlock`,
            data: { username: user }
        });
    });
});

// LIMIT IP VLESS
app.get("/limitvless", (req, res) => {
    const { user, iplimit, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user || !iplimit) {
        return res.status(400).json({ status: "error", message: "Missing parameters" });
    }

    const cmd = `printf "%s\\n" "${user}" "${iplimit}" | ${BASE_PATH}bot-ganti-ip-vless`;

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "Limit IP VLESS");
    });
});

// RECOVER/DETAIL VLESS
app.get("/recovervless", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-recover-vl`;

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "Detail VLESS");
    });
});

// SHOW ALL VLESS USERS
app.get("/showvless", (req, res) => {
    const { auth } = req.query;

    if (!validateAuth(auth, res)) return;

    const cmd = `${BASE_PATH}bot-member-vle`;

    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal mengambil data user VLESS" });
        }
        res.json({
            status: "success",
            message: "Data user VLESS berhasil diambil",
            data: { output: stdout }
        });
    });
});

// CHECK LOGIN VLESS
app.get("/loginvless", (req, res) => {
    const { auth } = req.query;

    if (!validateAuth(auth, res)) return;

    const cmd = `${BASE_PATH}bot-cek-vless`;

    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal memeriksa login VLESS" });
        }
        res.json({
            status: "success",
            message: "Data login VLESS berhasil diambil",
            data: { output: stdout }
        });
    });
});

// ========================= TROJAN ENDPOINTS =========================

// CREATE TROJAN
app.get("/createtrojan", (req, res) => {
    const { user, exp, iplimit, quota, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user || !exp || !quota || !iplimit) {
        return res.status(400).json({ status: "error", message: "Missing parameters" });
    }

    const uuid = require('crypto').randomUUID ? require('crypto').randomUUID() : require('uuid').v4();
    
    const cmd = `printf "%s\\n" "${user}" "${uuid}" "${quota}" "${iplimit}" "${exp}" | ${BASE_PATH}bot-add-tro`;

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "Trojan");
    });
});

// TRIAL TROJAN
app.get("/trialtrojan", (req, res) => {
    const { user, exp, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    const username = user || `trial${Math.floor(1000 + Math.random() * 9000)}`;
    const duration = exp || "60";
    
    const cmd = `printf "%s\\n" "${username}" "${duration}" | ${BASE_PATH}bot-trial-tro`;

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "Trial Trojan");
    });
});

// RENEW TROJAN
app.get("/renewtrojan", (req, res) => {
    const { user, exp, iplimit, quota, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user || !exp || !iplimit || !quota) {
        return res.status(400).json({ status: "error", message: "Missing parameters" });
    }

    const cmd = `printf "%s\\n" "${user}" "${exp}" "${quota}" "${iplimit}" | ${BASE_PATH}bot-renew-tro`;

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "Renew Trojan");
    });
});

// DELETE TROJAN
app.get("/deletetrojan", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-del-tro`;

    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal menghapus akun Trojan" });
        }
        res.json({
            status: "success",
            message: `Akun Trojan ${user} berhasil dihapus`,
            data: { username: user }
        });
    });
});

// LOCK TROJAN
app.get("/locktrojan", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-lock-tr`;

    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal meng-lock akun Trojan" });
        }
        res.json({
            status: "success",
            message: `Akun Trojan ${user} berhasil di-lock`,
            data: { username: user }
        });
    });
});

// UNLOCK TROJAN
app.get("/unlocktrojan", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-unlock-tr`;

    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal meng-unlock akun Trojan" });
        }
        res.json({
            status: "success",
            message: `Akun Trojan ${user} berhasil di-unlock`,
            data: { username: user }
        });
    });
});

// LIMIT IP TROJAN
app.get("/limittrojan", (req, res) => {
    const { user, iplimit, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user || !iplimit) {
        return res.status(400).json({ status: "error", message: "Missing parameters" });
    }

    const cmd = `printf "%s\\n" "${user}" "${iplimit}" | ${BASE_PATH}bot-ganti-ip-trojan`;

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "Limit IP Trojan");
    });
});

// RECOVER/DETAIL TROJAN
app.get("/recovertrojan", (req, res) => {
    const { user, auth } = req.query;

    if (!validateAuth(auth, res)) return;

    if (!user) {
        return res.status(400).json({ status: "error", message: "Missing username parameter" });
    }

    const cmd = `printf "%s\\n" "${user}" | ${BASE_PATH}bot-recover-tr`;

    exec(cmd, (error, stdout, stderr) => {
        handleExecResult(error, stdout, stderr, res, "Detail Trojan");
    });
});

// SHOW ALL TROJAN USERS
app.get("/showtrojan", (req, res) => {
    const { auth } = req.query;

    if (!validateAuth(auth, res)) return;

    const cmd = `${BASE_PATH}bot-member-tro`;

    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal mengambil data user Trojan" });
        }
        res.json({
            status: "success",
            message: "Data user Trojan berhasil diambil",
            data: { output: stdout }
        });
    });
});

// CHECK LOGIN TROJAN
app.get("/logintrojan", (req, res) => {
    const { auth } = req.query;

    if (!validateAuth(auth, res)) return;

    const cmd = `${BASE_PATH}bot-cek-tr`;

    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            return res.json({ status: "error", message: stderr || "Gagal memeriksa login Trojan" });
        }
        res.json({
            status: "success",
            message: "Data login Trojan berhasil diambil",
            data: { output: stdout }
        });
    });
});

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
        console.error("Error:", stderr);
        return res.json({ status: "error", message: stderr || `Gagal melakukan operasi ${serviceName}` });
    }

    // Parsing output shell menjadi JSON
    const data = parseSSHOutput(stdout);

    res.json({
        status: "success",
        message: `${serviceName} berhasil`,
        data: data
    });
}

// Menjalankan server
app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server API berjalan di port ${PORT}`);
    console.log(`Base path: ${BASE_PATH}`);
    console.log(`Available endpoints:`);
    console.log(`- SSH: /createssh, /trialssh, /renewssh, /deletessh, /lockssh, /unlockssh, /limitssh, /recoverssh, /showssh, /loginssh`);
    console.log(`- VMESS: /createvmess, /trialvmess, /renewvmess, /deletevmess, /lockvmess, /unlockvmess, /limitvmess, /recovervmess, /showvmess, /loginvmess`);
    console.log(`- VLESS: /createvless, /trialvless, /renewvless, /deletevless, /lockvless, /unlockvless, /limitvless, /recovervless, /showvless, /loginvless`);
    console.log(`- TROJAN: /createtrojan, /trialtrojan, /renewtrojan, /deletetrojan, /locktrojan, /unlocktrojan, /limittrojan, /recovertrojan, /showtrojan, /logintrojan`);
});