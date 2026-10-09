<div align="center">

<h1>Codex Connect Fix</h1>

<b>Windows · Codex Desktop (Microsoft Store)</b> · <code>reconnects 5 times before every prompt · remote control fails</code>
<b>English</b> | <a href="./README.md">简体中文</a>

No TUN mode. Proxy for Codex only — browsers and everything else stay direct<br>

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

<a href="./AGENT_PROMPTS.md">🤖 Deployment prompt: let an agent do it</a> · <a href="./scripts/install-shortcut.ps1">Method A launcher</a> · <a href="./scripts/set-user-proxy.ps1">Method B user-level vars</a>

</div>

---

**Before every single instruction, Codex relentlessly reconnects five times before it even starts thinking** (see the screenshot below), and connecting to your PC from a phone fails too. The cause is not a slow network: **some Codex child processes never pick up the system proxy at all.** This project offers two zero-side-effect fixes — a launcher script used only for Codex, or a set of user-level proxy environment variables. **Neither requires your proxy client's TUN mode**, so WeChat, browsers and everything else stay on a direct connection.

> ⚠️ You must supply your own local HTTP proxy (Clash / FlClash / Mihomo, default port 7890) — this project does not include one.
> ⚠️ After changing anything, **fully exit and restart Codex**; a running process will never re-read environment variables.

## 🤖 Send this to an agent

Copy the block below to an agent with **local PowerShell access** (Claude Code, WorkBuddy, or Codex itself). It inspects read-only first, then acts, and finally pastes the diagnostic output back to you instead of just saying "done".

```text
Fix the "Codex keeps reconnecting / phone-to-PC remote connection fails" problem on my Windows machine.
Root cause is confirmed: some Codex child processes never inherit the system proxy.
The fix is to set the proxy environment variables before Codex starts.

1) Read-only first: get InstallLocation and Version from
   Get-AppxPackage -Name OpenAI.Codex (the folder name carries the version — never hard-code it);
   confirm the proxy is listening with Get-NetTCPConnection -State Listen -LocalPort 7890.
   If it is not listening, stop and tell me to start my proxy client first.
2) Method A (required): copy the four files from scripts/ into %APPDATA%\Codex-launcher\, then run
   powershell -NoProfile -ExecutionPolicy Bypass -File .\install-shortcut.ps1
   Hard constraint: .cmd and .vbs files must contain no non-ASCII characters
   (cmd.exe parses them with the OEM code page and will merge lines).
3) Method B (only if I need remote connections): run scripts/set-user-proxy.ps1 to write
   user-level HTTP_PROXY / HTTPS_PROXY / ALL_PROXY and NO_PROXY. Use 'User', never 'Machine',
   and do not use setx.
4) Acceptance: run start-codex-proxy.cmd --check and paste the complete output; and state
   explicitly that Codex must be fully exited and restarted for the change to take effect.

Prohibited: enabling TUN mode; modifying any Codex installation file; changing machine-level
environment variables. If any step fails, stop and report the raw error.
```

The full version (with per-step acceptance criteria) lives in [`AGENT_PROMPTS.md`](./AGENT_PROMPTS.md).

## 1️⃣ What it fixes

| Symptom | Fixed? | Method |
| --- | --- | --- |
| Codex reconnects five times before answering every prompt | ✅ | A |
| Codex spins forever, reports request timed out | ✅ | A |
| **Connecting to the PC from a phone fails; Codex remote fails** | ✅ | **B** |
| Codex cannot drive the browser or its networked child processes | ✅ | A (B is safer) |
| TUN mode made WeChat hang and domestic sites slow | ✅ without TUN | A + B |
| After a Store update the old launcher says "file not found" | ✅ | no hard-coded version |
| You have no local proxy at all | ❌ | — |

<div align="center">
<img src="./docs/symptom-reconnect-5times.jpg" width="821" alt="Codex reconnecting 5/5, request timed out">
<br>
<sub>Figure 1: how it looked before the fix — every prompt stalled at "reconnecting 5/5 / request timed out".</sub>
</div>

## 2️⃣ The two methods

### Method A — a dedicated launcher script (recommended, smallest blast radius)

Before Codex starts, set the three proxy variables in the current process, then launch Codex. It and every child it spawns inherit the proxy; nothing else is affected.

```bat
@echo off
set "HTTP_PROXY=http://127.0.0.1:7890"
set "HTTPS_PROXY=http://127.0.0.1:7890"
set "ALL_PROXY=http://127.0.0.1:7890"
set "NO_PROXY=localhost,127.0.0.1,::1"
start "" "C:\Program Files\WindowsApps\OpenAI.Codex_26.908.4834.0_x64__2p2nqsd0c76g0\app\ChatGPT.exe"
```

<div align="center">
<img src="./docs/method-a-launcher-cmd.png" width="737" alt="The launcher script">
<br>
<sub>Figure 2: that is the whole thing — short enough to retype. ⚠️ But look at the last line: <code>26.908.4834.0</code> is <strong>hard-coded</strong>, and a Store update renames the folder (it has since become <code>26.928.3736.0</code>), so double-clicking it is guaranteed to fail with "file not found". This project resolves the package at run time with <code>Get-AppxPackage</code>, so Store updates never require edits again.</sub>
</div>

One-command install (handles version resolution, hides the console, creates an official-icon shortcut):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-shortcut.ps1
```

### Method B — user-level proxy environment variables (for remote / background processes)

**Why B is still needed**: phone-to-PC connections and Codex's remote capability run in Codex **background processes**. Those are not launched by the Method A script, so they never inherit its process-level variables. Only user-level variables reach them.

<div align="center">
<img src="./docs/method-b-user-env.png" width="757" alt="User-level environment variables">
<br>
<sub>Figure 3: user-level environment variables. The key detail is the third argument <code>'User'</code> — it writes to the current user (registry <code>HKCU\Environment</code>) and needs no administrator rights. Do not use <code>'Machine'</code>, and do not reach for <code>setx</code> (it truncates at 1024 characters and fails silently when it does).</sub>
</div>

```powershell
# apply
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\set-user-proxy.ps1
# inspect current state
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\set-user-proxy.ps1 -Status
# one-command rollback
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\set-user-proxy.ps1 -Undo
```

> ⚠️ **B has a cost**: user-level variables are inherited by **every new process** you start, so command-line tools such as git / pip / curl begin using the proxy and some of them may slow down or fail. Method A is therefore the default; add B only when you actually need remote capability, and run `-Undo` when you no longer do.

### Choosing between them

| | Method A launcher | Method B user-level variables |
| --- | --- | --- |
| Scope | Only the Codex process tree started from it | Every new process for the current user |
| Fixes remote / background processes | ❌ | ✅ |
| Affects WeChat and other apps | Not at all | ⚠️ Inherited, may slow down |
| Needs administrator | ❌ | ❌ |
| Best for | Making only Codex use the proxy | Remote control, or not wanting to launch from a specific place |

**The two methods are independent and can be used together.**

## 3️⃣ Why it works

### TUN mode does fix it — which is exactly why nobody wants it on

TUN mode forces **all traffic** through the proxy tunnel, dragging WeChat, domestic websites and intranet services into the proxy path — which produces hangs, dropped connections and slow DNS. Sacrificing the whole machine's browsing experience to fix one application is a poor trade, and the problem does not require global interception at all.

### Why setting an environment variable is enough

`HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY` are the de-facto standard for proxy configuration. A process reads them **once, at creation**, and **a child process inherits its parent's environment** — so as long as the variables are set before Codex starts, Codex and everything it subsequently spawns (browser control, networked helpers) goes through the proxy. Adding `NO_PROXY=localhost,127.0.0.1,::1` keeps loopback direct, so Codex's communication with its local helpers never takes a detour.

### So why not just change the system-wide variables?

Because system-level and user-level variables are inherited by **every** new process — you set out to fix Codex and drag every other application into the proxy along the way. Method A uses `setlocal` to confine the variables to that one cmd process and its children; **they vanish the moment cmd exits**, which is the smallest possible blast radius. Method B exists solely to cover the one case Method A cannot reach — background processes that are not launched by the script — and it carries the corresponding cost, which is why it is optional and reversible.

### Measured record: why the version must be resolved at run time

| Item | Value |
| --- | --- |
| Store package folder hard-coded in the old launcher | `OpenAI.Codex_26.908.4834.0_x64__2p2nqsd0c76g0` |
| Actual store package folder at the time of this check | `OpenAI.Codex_26.928.3736.0_x64__2p2nqsd0c76g0` |
| Conclusion | The folder name genuinely changes with updates, so a hard-coded script is guaranteed to break |

## 📥 Download and install

Grab `codex-connect-fix-v1.0.1.zip` from [**Releases**](../../releases/latest), unzip it, then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-shortcut.ps1
```

**Dependencies: none** — built entirely on the Windows-bundled PowerShell 5.1 and Windows Script Host.
`-ExecutionPolicy Bypass` is not optional: the default policy on the author's machine is `Restricted`, which rejects the script outright.

## ⚠️ Limits

- **No bundled proxy**: this project only tells Codex the address; you must run the proxy yourself (default port 7890, one line to change).
- **Codex must be fully exited first**: environment variables take effect only at process creation, and a running process cannot be changed retroactively.
- **No Codex files are modified**: Method A writes no registry keys; Method B writes exactly one location, `HKCU\Environment`, and is reversible in one command. The system proxy setting is never touched.
- **Store build only**: the package name must be `OpenAI.Codex`; a self-installed Codex CLI is not covered.
- **HTTP-style variables only**: the injected values are `http://` URLs, so a SOCKS-only port requires enabling the HTTP/mixed port in your proxy client.
- **Method B is double-edged**: see the cost note above; `-Undo` is always available.

## 🗂 Project structure

```text
AGENT_PROMPTS.md                   Bilingual deployment prompt, ready to hand to an agent
scripts/install-shortcut.ps1       Method A one-command install: copy files / extract icon / create shortcut (-Uninstall)
scripts/start-codex-proxy.cmd      Method A entry point: sets the 4 variables, then calls the core logic
scripts/start-codex-proxy.ps1      Method A core: resolve Store version -> diagnose -> launch (--check = diagnose only)
scripts/run-codex-hidden.vbs       Console-hiding wrapper
scripts/set-user-proxy.ps1         Method B: write user-level variables (-Status / -Undo)
docs/symptom-reconnect-5times.jpg  Figure 1, the failure in the wild
docs/method-a-launcher-cmd.png     Figure 2, the Method A script
docs/method-b-user-env.png         Figure 3, Method B user-level variables
```

## ❓ FAQ

<details>
<summary><b>It still reconnects after I followed the steps</b></summary>

Check three things in order: (1) was Codex **fully exited** before you restarted it (including the tray icon)? (2) is the proxy port genuinely listening — run `start-codex-proxy.cmd --check` and read the `Proxy port` line; (3) did you only apply Method A while your scenario (remote / background processes) requires Method B?
</details>

<details>
<summary><b>Double-clicking says "file not found"</b></summary>

You are still using the old script with a hard-coded version number. Reinstall with this project's `install-shortcut.ps1`; it resolves the current Store version at run time.
</details>

<details>
<summary><b>git / pip got slow or started failing after Method B</b></summary>

That is expected — user-level variables are inherited by every new process. Either set a per-tool `NO_PROXY`, or roll it back: `set-user-proxy.ps1 -Undo`.
</details>

<details>
<summary><b>Does this project touch my Codex installation or my system?</b></summary>

No. Method A only sets variables inside its own process and then launches Codex with `Start-Process`; Method B writes one location, `HKCU\Environment`, and is reversible in one command. **No Codex file is modified, no machine-level variable is changed, and the system proxy setting is left alone.**
</details>

## 📄 Legal and disclaimer

- This repository is **not affiliated with OpenAI** in any way and is not an official project. Codex, ChatGPT and the associated icon are trademarks and copyrighted works of OpenAI.
- The tool **does not modify Codex itself** and bypasses no payment, authentication or regional restriction; it only sets proxy environment variables locally — where the proxy comes from and whether it works is entirely your responsibility.
- Verify that your network environment and the proxy service you use comply with local law and with OpenAI's terms of service.
- The scripts are provided "as is", without warranty of any kind. Any network configuration change, account risk or other consequence arising from their use is **borne by the user**.

## 📮 Contact

| | |
| --- | --- |
| Issues | [Issues](https://github.com/gdSHAY/codex-connect-fix/issues) (please include the full `--check` output) |
| Repository | <https://github.com/gdSHAY/codex-connect-fix> |
| Related | [codex-sandbox-doctor](https://github.com/gdSHAY/codex-sandbox-doctor): fixes the Codex sandbox "Windows setup incomplete" loop |

## 📄 License

**MIT License** — see [LICENSE](./LICENSE).

<div align="center">
<sub>This README is bilingual — <a href="./README.md">简体中文</a> / <b>English</b>. Switch with the link at the top.</sub>
</div>
