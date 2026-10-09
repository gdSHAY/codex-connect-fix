# 交给 Agent 的部署提示词

把下面整段复制给一个**具有本机 PowerShell 权限**的 Agent（Claude Code / WorkBuddy / Codex 本人都可以）。
提示词要求它「先只读取证 → 再动手 → 最后给证据」，不猜、不重装、不改系统级设置。

> 只想自己动手：跳过本页，直接看 [README](./README.md) 的「2️⃣ 使用的方法」。

---

## 中文提示词

```text
帮我修 Windows 上「Codex 桌面版反复重连 / 手机远程连接电脑失败」的问题。

根因判断（已确认，不用再论证）：Codex 的部分子进程没有继承到系统代理，
所以它在发指令前会死命重连。修法是在启动 Codex 之前先把代理环境变量设好，
让 Codex 和它拉起的子进程都继承代理地址，同时让本机回环保持直连。

按下面顺序做，每一步都「先只读取证、再动手」，不要跳步：

【第 1 步 · 只读取证】
1. Get-AppxPackage -Name OpenAI.Codex
   记下 InstallLocation 和 Version。
   ⚠️ 目录名里带版本号（形如 OpenAI.Codex_26.928.3736.0_x64__...），
   任何情况下都不要把完整路径写死到脚本里。
2. 用 Get-NetTCPConnection -State Listen -LocalPort 7890 确认本地代理在监听。
   如果没在监听：停下来告诉我先启动 Clash / FlClash，不要继续往下做。
3. 把我本机"环境变量"对话框或注册表 HKCU\Environment 里现有的
   HTTP_PROXY / HTTPS_PROXY / ALL_PROXY / NO_PROXY 值报给我。

【第 2 步 · 方案 A：专用启动器（必做）】
1. 把仓库 scripts/ 下的 4 个文件复制到 %APPDATA%\Codex-launcher\：
   start-codex-proxy.cmd、start-codex-proxy.ps1、run-codex-hidden.vbs、install-shortcut.ps1
2. 运行 install-shortcut.ps1（必须带 -ExecutionPolicy Bypass）：
   powershell -NoProfile -ExecutionPolicy Bypass -File .\install-shortcut.ps1
   它会复制文件、从 Codex 安装包里提取官方图标、在桌面创建「启动 Codex 代理」快捷方式。
3. 硬约束，务必遵守：
   - .cmd 与 .vbs 文件里**不能出现任何非 ASCII 字符**。
     cmd.exe 按 OEM 代码页（简中 936）解析批处理，UTF-8 中文的某些字节序列
     会吞掉行尾的 CR，导致两行被拼成一行、报出莫名其妙的"不是内部或外部命令"。
     所有中文提示只能放在 .ps1 里，且 .ps1 必须存成 UTF-8 with BOM。
   - .cmd 里不要裸写 powershell，用
     %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe 并保留裸名兜底。

【第 3 步 · 方案 B：用户级变量（只有我要用远程 / 后台进程时才做）】
1. 运行 scripts/set-user-proxy.ps1，把 HTTP_PROXY / HTTPS_PROXY / ALL_PROXY
   写成**用户级**变量，同时设 NO_PROXY=localhost,127.0.0.1,::1。
   第三个参数必须是 'User'，不要用 'Machine'，也不要用 setx
   （setx 有 1024 字符截断且超长静默失败）。
2. 做完告诉我代价：用户级变量会被该用户下**所有新进程**继承，
   git / pip / curl 这类命令行工具会开始走代理，个别软件可能因此变慢或失败。
   把一键撤销的命令一起给我：set-user-proxy.ps1 -Undo

【第 4 步 · 验收，必须给我证据，不要只说"已完成"】
1. 运行 %APPDATA%\Codex-launcher\start-codex-proxy.cmd --check
   把**完整原始输出**贴给我，里面必须有：
   安装版本 / 主程序路径 / 代理端口是否在监听 / 4 个变量是否已注入。
2. 明确告诉我：Codex 必须先**完全退出**（含托盘图标）再重启，改动才生效。
3. 如果我要用远程连接，再跑一次 set-user-proxy.ps1 -Status，把用户级变量的
   当前值贴给我。

【禁止事项】
- 不要开启代理软件的 TUN 模式。它会接管全部流量，导致微信等国内应用卡死断线。
- 不要修改 Codex 的任何安装文件，不要重装 Codex。
- 不要修改系统级（Machine）环境变量。
- 任何一步失败就停下来报告原始报错，不要猜、不要静默跳过。
```

---

## English prompt

```text
Fix the "Codex Desktop keeps reconnecting / phone-to-PC remote connection fails"
problem on my Windows machine.

Root cause (already confirmed, do not re-litigate): some Codex child processes never
inherit the system proxy, so Codex retries the connection before every instruction.
The fix is to set the proxy environment variables BEFORE Codex starts, so Codex and
the children it spawns inherit the proxy address while loopback traffic stays direct.

Work through the steps below in order. For every step: inspect read-only first, then act.
Do not skip steps.

[Step 1 - read-only reconnaissance]
1. Run: Get-AppxPackage -Name OpenAI.Codex
   Record InstallLocation and Version.
   WARNING: the folder name contains the version (e.g. OpenAI.Codex_26.928.3736.0_x64__...).
   Never hard-code that full path into any script.
2. Run: Get-NetTCPConnection -State Listen -LocalPort 7890 to confirm the local proxy
   is listening. If it is not: STOP and tell me to start Clash / FlClash first.
3. Report the current HTTP_PROXY / HTTPS_PROXY / ALL_PROXY / NO_PROXY values from
   my user environment (registry key HKCU\Environment).

[Step 2 - Method A: the dedicated launcher (required)]
1. Copy the four files from the repository's scripts/ folder into %APPDATA%\Codex-launcher\:
   start-codex-proxy.cmd, start-codex-proxy.ps1, run-codex-hidden.vbs, install-shortcut.ps1
2. Run install-shortcut.ps1 (the -ExecutionPolicy Bypass flag is mandatory):
   powershell -NoProfile -ExecutionPolicy Bypass -File .\install-shortcut.ps1
   It copies the files, extracts the official icon from the Codex package, and creates
   a desktop shortcut.
3. Hard constraints, follow them exactly:
   - .cmd and .vbs files must contain NO non-ASCII characters.
     cmd.exe parses batch files using the OEM code page (936 on zh-CN); certain UTF-8
     byte sequences swallow the trailing CR and merge two lines into one, producing a
     nonsense "is not recognized as an internal or external command" error.
     All localized text belongs in .ps1 files, saved as UTF-8 with BOM.
   - Do not invoke bare `powershell` from a .cmd. Use
     %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe with a bare-name fallback.

[Step 3 - Method B: user-level variables (only if I need remote / background processes)]
1. Run scripts/set-user-proxy.ps1 to write HTTP_PROXY / HTTPS_PROXY / ALL_PROXY as
   USER-level variables, plus NO_PROXY=localhost,127.0.0.1,::1.
   The scope argument must be 'User', never 'Machine', and do not use setx
   (it truncates at 1024 characters and fails silently when it does).
2. Tell me the cost: user-level variables are inherited by EVERY new process for this
   user, so git / pip / curl will start using the proxy and some tools may slow down or
   fail. Give me the one-command rollback: set-user-proxy.ps1 -Undo

[Step 4 - acceptance: give me evidence, do not just say "done"]
1. Run %APPDATA%\Codex-launcher\start-codex-proxy.cmd --check and paste the COMPLETE raw
   output. It must include: installed version / main program path / whether the proxy port
   is listening / whether all four variables were injected.
2. State explicitly that Codex must be FULLY EXITED (including the tray icon) and
   restarted before the change takes effect.
3. If I use remote connections, also run set-user-proxy.ps1 -Status and paste the current
   user-level values.

[Prohibited]
- Do not enable your proxy client's TUN mode. It takes over all traffic and makes
  domestic apps such as WeChat hang or disconnect.
- Do not modify any Codex installation file and do not reinstall Codex.
- Do not modify machine-level (system-wide) environment variables.
- If any step fails, stop and report the raw error. Do not guess, do not silently skip.
```

---
