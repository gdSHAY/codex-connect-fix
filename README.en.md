<div align="center">

<h1>Codex Connect Fix · Per-App Proxy Launcher</h1>

<b>Windows · Codex Desktop (Microsoft Store)</b> · <code>cannot connect · reconnect loop · breaks after Store update</code>
<b>English</b> | <a href="./README.md">简体中文</a>

Proxy injected into Codex only · no system env vars touched · survives Store updates<br>

<a href="https://github.com/gdSHAY/codex-connect-fix/stargazers"><img src="https://img.shields.io/github/stars/gdSHAY/codex-connect-fix?style=flat-square&label=Stars&color=06d6a0" alt="Stars"></a>
<a href="https://github.com/gdSHAY/codex-connect-fix/forks"><img src="https://img.shields.io/github/forks/gdSHAY/codex-connect-fix?style=flat-square&label=Forks&color=4cc9f0" alt="Forks"></a>
<a href="https://github.com/gdSHAY/codex-connect-fix/issues"><img src="https://img.shields.io/github/issues/gdSHAY/codex-connect-fix?style=flat-square&label=Issues&color=ffd166" alt="Issues"></a>
<img src="https://img.shields.io/github/last-commit/gdSHAY/codex-connect-fix?style=flat-square&label=Updated&color=ff4d6d" alt="Last update">

<br>

<img src="https://img.shields.io/badge/Platform-Windows_10_%2F_11-0078d4?style=flat-square" alt="Windows 10 / 11">
<img src="https://img.shields.io/badge/Shell-PowerShell_5.1-5391fe?style=flat-square&logo=powershell&logoColor=white" alt="PowerShell 5.1">
<img src="https://img.shields.io/badge/Deps-None-06d6a0?style=flat-square" alt="No third-party dependency">
<img src="https://img.shields.io/badge/Docs-English_%2F_中文-8b5cf6?style=flat-square" alt="English and Chinese">

<br><br>

<a href="./scripts/install-shortcut.ps1">One-command installer</a> · <a href="./scripts/start-codex-proxy.ps1">Auditable core logic</a> · <a href="./scripts/start-codex-proxy.cmd">Manual entry point</a>

</div>

---

**This repository solves one concrete problem: the Microsoft Store build of Codex Desktop cannot reach the server — it spins forever or reconnects in a loop — even though your local proxy is up.** The cause is that the Codex process never receives the proxy environment variables; the system-wide proxy setting does not reach some of its child processes. This tool uses a per-app launcher that injects `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY` into **the Codex process tree started from it, and nothing else**.

It also fixes a real flaw in the original launcher: the Store package folder was hard-coded together with its version number (`OpenAI.Codex_26.908.4834.0_x64__...`), so a single automatic Store update broke the shortcut with a "file not found" error. This version resolves the current package at run time via `Get-AppxPackage`, so **nothing needs editing after a Store update**.

> ⚠️ **This tool does not include a proxy. You need a working local HTTP proxy** (Clash / FlClash / Mihomo, default port `7890`).
> ⚠️ **Codex must be fully closed first**, otherwise the variables cannot be injected into an already-running process tree.
> See [Prerequisites and limits](#-prerequisites-and-limits-important).

## 🎬 What it looks like

There is no GUI here — the product is a shortcut that launches Codex. So the only honest "screen" to show is the official Codex icon plus the launcher's **real diagnostic output**.

<img src="./docs/codex-app-icon.png" alt="Official Codex icon" width="128">

<sub>(1) The icon is extracted directly from the Codex installation package (`app\resources\icon-chatgpt.ico`, which contains eight sizes from 16 to 256). It is not a mock-up or a placeholder. The installer copies it locally so the shortcut icon does not turn into a blank page after a Store update changes the package folder.</sub>

The launcher ships a check-only mode that prints which version was resolved, whether the proxy port is actually listening, and whether the variables were injected. Verbatim output from the author's machine:

```text
=== Codex proxy launcher - diagnostics ===
Version      : 26.928.3736.0
Install dir  : C:\Program Files\WindowsApps\OpenAI.Codex_26.928.3736.0_x64__2p2nqsd0c76g0
Main program : C:\Program Files\WindowsApps\OpenAI.Codex_26.928.3736.0_x64__2p2nqsd0c76g0\app\ChatGPT.exe
Proxy        : http://127.0.0.1:7890
Proxy port   : 7890 is listening (PID 12344)
Injected     : HTTP_PROXY / HTTPS_PROXY / ALL_PROXY / NO_PROXY
NO_PROXY     : localhost,127.0.0.1,::1

Check mode: Codex was not started.
```

<sub>(2) One screen validates three things at once: version-independent resolution works (the folder name carries the real current version), the proxy port is genuinely reachable, and all four variables are present in the process before Codex is launched. Anything that fails is printed explicitly instead of leaving you guessing why it "cannot connect". The console output is localized in Chinese by default; this block is the same output with labels translated for readability.</sub>

## 📥 Download and install

Grab it from [**Releases**](../../releases/latest).

| File | Size | Purpose |
| --- | --- | --- |
| `codex-connect-fix-v1.0.0.zip` | ~99 KB | All 4 scripts + bilingual docs + official icon, unzip and run |
| [`scripts/install-shortcut.ps1`](./scripts/install-shortcut.ps1) | 5.5 KB | One-command install: copy files, extract icon, create desktop shortcut |
| [`scripts/start-codex-proxy.ps1`](./scripts/start-codex-proxy.ps1) | 4.7 KB | Core logic: resolve version, diagnose, launch |
| [`scripts/start-codex-proxy.cmd`](./scripts/start-codex-proxy.cmd) | 2.0 KB | Manual entry point: sets proxy variables, then calls the core logic |
| [`scripts/run-codex-hidden.vbs`](./scripts/run-codex-hidden.vbs) | 1.7 KB | Console-hiding wrapper the shortcut targets |

**Dependencies: none.** Everything uses Windows built-ins (PowerShell 5.1 and Windows Script Host).

### Install (recommended)

1. Unzip anywhere, for example `D:\CodexLauncher`
2. Hold `Shift`, right-click in that folder, choose "Open PowerShell window here", then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-shortcut.ps1
```

3. A desktop shortcut named in Chinese by default appears; rename it with the `-ShortcutName` parameter if you prefer

> ⚠️ Do not drop `-ExecutionPolicy Bypass`. On the author's machine the policy defaults to `Restricted`, and `& .\install-shortcut.ps1` fails with "running scripts is disabled on this system". `start-codex-proxy.cmd` already carries that flag internally, so only the install step needs it typed out.

> ⚠️ Antivirus or SmartScreen may flag the `.vbs`. Its only job is to hide the console window (`WScript.Shell.Run` with window style 0). If you would rather avoid it, use `start-codex-proxy.cmd` directly and accept a brief console flash.

### Portable (no install)

You do not have to install anything: just run `scripts/start-codex-proxy.cmd`. The trade-offs are a flashing console window and no desktop icon.

### From source

```powershell
git clone https://github.com/gdSHAY/codex-connect-fix.git
cd codex-connect-fix
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-shortcut.ps1
```

### Uninstall

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-shortcut.ps1 -Uninstall
```

This removes only `%APPDATA%\Codex-launcher\` and the desktop shortcut. Codex itself and every system setting are left untouched.

## ✨ Symptom matrix

Match your symptom first instead of installing blindly. **The "fixed?" column is the honest boundary of this tool**:

| What you see | Fixed? | Why |
| --- | --- | --- |
| Codex spins forever or reports a network error, while browsers work fine | ✅ | Classic sign: the Codex process never got the proxy variables |
| Codex reconnects in a loop; its remote/online features are unusable | ✅ | Same root cause — this tool gives the process tree its proxy |
| After a Store update the old shortcut says "file not found" | ✅ | The original hard-coded a versioned folder; this one resolves at run time |
| A console window flashes on every launch and looks like an error | ✅ | The `.vbs` wrapper sets window style to hidden |
| The shortcut icon turned into a blank page | ✅ | The icon is copied locally instead of pointing into a versioned folder |
| You have no local proxy at all | ❌ | This tool **does not include** a proxy; it only tells Codex the address |
| You double-click the shortcut while Codex is already running | ❌ | Env vars are not injected into an existing process tree; exit Codex first |
| You use a self-installed Codex CLI instead of the Store app | ❌ | Only the `OpenAI.Codex` Store package is handled |
| Your proxy only speaks SOCKS | ❌ | The injected variables are `http://` URLs |

## ⚙️ Three steps to start

1. **Start your proxy first**: open Clash / FlClash and confirm the local HTTP port is listening (default `7890`)
2. **Install once**: run `install-shortcut.ps1` as shown above
3. **Every time after that**: double-click the desktop shortcut and Codex comes up connected

**Supported ways to invoke it**

| Way | Command | Purpose |
| --- | --- | --- |
| Desktop shortcut | double-click | Daily use, silent launch |
| Check mode | `start-codex-proxy.cmd --check` | Run this first when it cannot connect; it tells you which step failed |
| Core logic directly | `start-codex-proxy.ps1 -Check` | Same diagnostic, in the console, easy to paste into an issue |

## ⚠️ Prerequisites and limits (important)

> This is the section worth reading. It states plainly **what the tool cannot do**, which explains the tool better than a feature list.

### 1. You must supply the proxy

The launcher does exactly one thing: it writes the address of an already-running local proxy into the Codex process environment. It **does not provide** a proxy, ship any nodes, or change any system proxy setting.

If nothing is listening on the port, the launcher tells you with a message box instead of silently starting a Codex that cannot connect:

```text
Local proxy http://127.0.0.1:7890 is not listening.

Start Clash / FlClash and make sure port 7890 is open, then launch Codex.
```

### 2. Codex must be fully closed first

Environment variables are inherited **at process creation**. A process already running will not pick up new variables because you double-clicked a shortcut. The correct order is always: **fully exit Codex, then launch from the shortcut.**

The `Injected` line in the diagnostic output exists precisely so you can confirm this before launching.

### 3. It affects one process tree only

The variables are set inside the cmd process with `setlocal`, so they live and die with that child process. No registry writes, no `setx`, no change to the Internet Options system proxy. In practice:

- browsers and every other application are unaffected;
- once the launcher process exits, the variables cannot be found in the system environment.

### 4. The Store package folder changes — the main reason this repo exists

The original launcher hard-coded a versioned path:

```text
C:\Program Files\WindowsApps\OpenAI.Codex_26.908.4834.0_x64__2p2nqsd0c76g0\app\ChatGPT.exe
```

**Measured (2026-10)**: at the time it was hard-coded the version was `26.908.4834.0`; at the time of this check it had become `26.928.3736.0`. The folder name really did change, so the hard-coded launcher must fail with "file not found" after a Store update — and users rarely realise their own script went stale.

This version resolves at run time:

```powershell
$pkg = Get-AppxPackage -Name 'OpenAI.Codex' | Select-Object -First 1
$exe = Join-Path $pkg.InstallLocation 'app\ChatGPT.exe'
```

There is also a fallback: if a future package layout moves the main executable, the launcher searches the install directory recursively for it; if that also fails it shows a message box containing the install directory so you can file a useful issue.

### 5. Changing the proxy port is a one-line edit

Only this line in `start-codex-proxy.cmd` matters:

```bat
if not defined CODEX_PROXY set "CODEX_PROXY=http://127.0.0.1:7890"
```

Alternatively set the `CODEX_PROXY` environment variable beforehand (for example `set CODEX_PROXY=http://127.0.0.1:1080`) — the script prefers it and you do not touch the file.

### 6. Why the `.cmd` and `.vbs` comments are in English

Not for style — this is a bug that was actually hit: **cmd.exe parses `.cmd` files using the OEM code page** (936 on Simplified Chinese systems). If the file contains UTF-8 non-ASCII bytes, certain byte sequences consume the following carriage return as the second byte of a double-byte character, **merging two lines into one** and producing bizarre "is not recognized as an internal or external command" errors. That is exactly how the first version broke.

So: `.cmd` and `.vbs` are pure ASCII, and every localized message lives in `.ps1` files saved as **UTF-8 with BOM** (PowerShell 5.1 reads a file as UTF-8 only when it sees the BOM; otherwise it assumes ANSI and the text becomes mojibake).

### 7. Measured clarifications (2026-10)

| Common claim | Measured result |
| --- | --- |
| "Just turn on the system proxy and Codex follows it" | **False.** The system proxy was on in this very machine, yet Codex still could not connect without the injected variables. That is where this repo started. |
| "Store apps cannot be controlled through environment variables" | **False.** Process-tree inheritance works for Store apps too; the main process and its children both received `HTTPS_PROXY`. |
| "Just double-clicking a .ps1 works" | **Depends on the execution policy.** The default here was `Restricted`, which rejects it unless `-ExecutionPolicy Bypass` is passed. |

## 🧱 Tech stack

| | |
| --- | --- |
| Languages | Windows batch (cmd) + PowerShell 5.1 + VBScript |
| System dependencies | All built into Windows 10 / 11, **no third-party package required** |
| Key APIs | `Get-AppxPackage` (resolve the Store package), `Start-Process` (launch inheriting env), `Get-NetTCPConnection` (probe the port), `WScript.Shell.Run` (hide the window) |
| Distribution | A single zip through GitHub Releases; binaries and icons stay out of the git object store |
| Not present | No installer, no service, no resident process, no config file |

## 🗂 Project structure

```text
scripts/install-shortcut.ps1    One-command install: copy files / extract official icon / create shortcut (-Uninstall supported)
scripts/start-codex-proxy.cmd   Manual entry: sets the 4 proxy variables, then calls the core logic
scripts/start-codex-proxy.ps1   Core logic: resolve current Store version -> diagnose -> launch Codex
scripts/run-codex-hidden.vbs    Console-hiding wrapper that the shortcut targets
docs/codex-app-icon.png         Official icon used by this README (extracted from the package)
```

## ❓ FAQ

<details>
<summary><b>Nothing happens when I double-click the shortcut</b></summary>

Run check mode first; it names the failing step:

```powershell
%APPDATA%\Codex-launcher\start-codex-proxy.cmd --check
```

The three most common outcomes: the Store build of Codex is not found (not installed, or the package name changed); the proxy port is not listening (your proxy is off); or the main executable is missing from the resolved install directory (the package layout changed — open an issue and paste that directory).
</details>

<details>
<summary><b>Codex starts but reports a network error or keeps spinning</b></summary>

Check these three in order:

1. **Was Codex already running before the shortcut?** If so, exit it completely (including the tray icon) and launch from the shortcut again;
2. **Is your proxy listening on 127.0.0.1?** Confirm with the `Proxy port` line in the diagnostic — it reports the real listening state, not a guess;
3. **Is your proxy SOCKS-only?** The injected variables are `http://` URLs, so enable the HTTP/mixed port in your proxy client.
</details>

<details>
<summary><b>Do I need to reinstall after Codex updates from the Store?</b></summary>

No reinstall is needed, but **run the installer once more** so the official icon is re-extracted from the new package (otherwise the icon stays stale; functionality is unaffected). The launch logic itself is version-independent.
</details>

<details>
<summary><b>I changed my proxy port. How many places do I edit?</b></summary>

One: the `CODEX_PROXY` line in `%APPDATA%\Codex-launcher\start-codex-proxy.cmd`. Both the diagnostic and the launch read that single variable, so the change takes effect immediately. Consider editing the copy in the repository too, otherwise re-running the installer overwrites it back.
</details>

<details>
<summary><b>Does this launcher modify Codex itself?</b></summary>

No. It does three things: read the registry manifest to find the install directory, set four environment variables in its own process, and call `Start-Process` on the Codex main program. **It writes no Codex file, touches no registry key, and changes no system proxy setting.**
</details>

## 📄 Legal and disclaimer

- This repository is **not affiliated with OpenAI** in any way. Codex, ChatGPT and the associated icon are trademarks and copyrighted works of OpenAI; the icon extracted here is used solely to **identify the application** in the shortcut and documentation, and for nothing else.
- The tool **does not modify Codex itself** and bypasses no payment, authentication, or regional restriction. It only injects proxy environment variables locally — where the proxy comes from and whether it works is entirely your responsibility.
- Before use, verify that your network environment and the behaviour of your proxy service comply with local law and with OpenAI's terms of service.
- The scripts are provided "as is", without warranty of any kind. Any network configuration change, account risk, or other consequence arising from their use is **borne by the user**.

## 📮 Contact

| | |
| --- | --- |
| Issues | [Issues](https://github.com/gdSHAY/codex-connect-fix/issues) (please include the full `--check` output) |
| Repository | <https://github.com/gdSHAY/codex-connect-fix> |
| Related | [codex-sandbox-doctor](https://github.com/gdSHAY/codex-sandbox-doctor): fixes the Codex sandbox "Windows setup incomplete" loop |

## ⭐ Star History

<a href="https://star-history.com/#gdSHAY/codex-connect-fix&Timeline">
  <img src="https://api.star-history.com/svg?repos=gdSHAY/codex-connect-fix&type=Timeline" alt="Star History" width="620">
</a>

## 📄 License

This repository is released under the **MIT License**; see [LICENSE](./LICENSE). You may use, modify and redistribute it freely. The same license covers both the source and the packaged release.

<div align="center">
<sub>This README is bilingual — <a href="./README.md">简体中文</a> / <b>English</b>. Switch with the link at the top.</sub>
</div>
