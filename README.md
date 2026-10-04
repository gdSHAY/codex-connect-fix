<div align="center">

<h1>Codex 连接修复 · 按应用代理启动器</h1>

<b>Windows · Codex Desktop（微软商店版）</b> · <code>连不上 · 反复重连 · 商店更新后失效</code>
<b>简体中文</b> | <a href="./README.en.md">English</a>

只给 Codex 自己注入代理 · 不改系统环境变量 · 商店更新后不会失效<br>

<a href="https://github.com/gdSHAY/codex-connect-fix/stargazers"><img src="https://img.shields.io/github/stars/gdSHAY/codex-connect-fix?style=flat-square&label=Stars&color=06d6a0" alt="Stars"></a>
<a href="https://github.com/gdSHAY/codex-connect-fix/forks"><img src="https://img.shields.io/github/forks/gdSHAY/codex-connect-fix?style=flat-square&label=Forks&color=4cc9f0" alt="Forks"></a>
<a href="https://github.com/gdSHAY/codex-connect-fix/issues"><img src="https://img.shields.io/github/issues/gdSHAY/codex-connect-fix?style=flat-square&label=Issues&color=ffd166" alt="Issues"></a>
<img src="https://img.shields.io/github/last-commit/gdSHAY/codex-connect-fix?style=flat-square&label=Updated&color=ff4d6d" alt="Last update">

<br>

<img src="https://img.shields.io/badge/Platform-Windows_10_%2F_11-0078d4?style=flat-square" alt="Windows 10 / 11">
<img src="https://img.shields.io/badge/Shell-PowerShell_5.1-5391fe?style=flat-square&logo=powershell&logoColor=white" alt="PowerShell 5.1">
<img src="https://img.shields.io/badge/Deps-None-06d6a0?style=flat-square" alt="No third-party dependency">
<img src="https://img.shields.io/badge/Docs-中文_%2F_English-8b5cf6?style=flat-square" alt="Chinese and English">

<br><br>

<a href="./scripts/install-shortcut.ps1">一键安装脚本</a> · <a href="./scripts/start-codex-proxy.ps1">可审计的核心逻辑</a> · <a href="./scripts/start-codex-proxy.cmd">手动入口</a>

</div>

---

**这个仓库解决一个很具体的问题：微软商店版 Codex 桌面版连不上服务器、一直转圈或反复重连，而你的本机代理明明开着。** 原因是 Codex 进程没有拿到代理环境变量 —— 系统代理对它的部分子进程不生效。本工具用一个「按应用启动器」把 `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY` 注入到**从它启动的那棵 Codex 进程树**里，其余进程一概不受影响。

它顺带修掉了原始版本的一个硬伤：启动器里写死的商店包目录带版本号（`OpenAI.Codex_26.908.4834.0_x64__...`），商店一自动更新目录名就变，快捷方式直接报「找不到文件」。本版改为运行时用 `Get-AppxPackage` 解析当前版本，**商店更新后不需要再改任何东西**。

> ⚠️ **本工具不含代理，你必须有现成的本地 HTTP 代理**（Clash / FlClash / Mihomo 等，默认端口 `7890`）。
> ⚠️ **启动前必须先把 Codex 完全退出**，否则环境变量注入不进已经在跑的进程树。
> 详见 [前提条件与能力边界](#-前提条件与能力边界重要)。

## 🎬 它长什么样

本项目没有图形界面 —— 它就是一个会启动 Codex 的快捷方式，所以这里唯一能拍给你的「界面」是 Codex 官方图标，以及启动器在体检模式下的**真实输出**。

<img src="./docs/codex-app-icon.png" alt="Codex 官方图标" width="128">

<sub>① 图标直接从 Codex 安装包里提取（`app\resources\icon-chatgpt.ico`，含 16~256 八种尺寸），不是设计稿也不是占位图。安装脚本会把它复制到本地，这样商店更新换了目录，快捷方式的图标也不会变白纸。</sub>

启动器带一个只体检、不启动的模式，它会把「解析到了哪个版本、代理端口通不通、变量注没注进去」全部打出来。下面这段是本机实测输出，一字未改：

```text
=== Codex 代理启动器 · 体检 ===
安装版本 : 26.928.3736.0
安装目录 : C:\Program Files\WindowsApps\OpenAI.Codex_26.928.3736.0_x64__2p2nqsd0c76g0
主程序   : C:\Program Files\WindowsApps\OpenAI.Codex_26.928.3736.0_x64__2p2nqsd0c76g0\app\ChatGPT.exe
代理地址 : http://127.0.0.1:7890
代理端口 : 7890 正在监听（PID 12344）
已注入   : HTTP_PROXY / HTTPS_PROXY / ALL_PROXY / NO_PROXY
隐含变量 : NO_PROXY=localhost,127.0.0.1,::1

体检模式：未启动 Codex。
```

<sub>② 这一屏同时验证了三件事：版本无关解析成立（目录名里带着当前真实版本号）、代理端口确实是通的、四个环境变量在启动 Codex 之前就已经在这个进程里。任何一项不对都会当场写出来，而不是让你对着「连不上」猜。</sub>

## 📥 下载与安装

到 [**Releases**](../../releases/latest) 页面下载。

| 文件 | 大小 | 说明 |
| --- | --- | --- |
| `codex-connect-fix-v1.0.0.zip` | 约 99 KB | 4 个脚本 + 双语说明 + 官方图标，解压即用 |
| [`scripts/install-shortcut.ps1`](./scripts/install-shortcut.ps1) | 5.5 KB | 一键安装：复制文件、提取图标、建桌面快捷方式 |
| [`scripts/start-codex-proxy.ps1`](./scripts/start-codex-proxy.ps1) | 4.7 KB | 核心逻辑，解析版本 / 体检 / 启动 |
| [`scripts/start-codex-proxy.cmd`](./scripts/start-codex-proxy.cmd) | 2.0 KB | 手动入口，负责设好代理变量再调用上面那个 |
| [`scripts/run-codex-hidden.vbs`](./scripts/run-codex-hidden.vbs) | 1.7 KB | 隐藏黑窗的包装器，快捷方式指向它 |

**依赖：无。** 用的是 Windows 自带的 PowerShell 5.1 与 Windows Script Host，不需要装任何东西。

### 安装（推荐：一键）

1. 解压压缩包到任意目录（例如 `D:\CodexLauncher`）
2. 在该目录按住 `Shift` 右键 →「在此处打开 PowerShell 窗口」，执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-shortcut.ps1
```

3. 桌面上会出现「启动 Codex 代理」快捷方式

> ⚠️ `-ExecutionPolicy Bypass` 不能省 —— 本机实测执行策略默认是 `Restricted`，直接 `& .\install-shortcut.ps1` 会报「在此系统上禁止运行脚本」。`start-codex-proxy.cmd` 内部已经自带了这个参数，所以只有安装这一步需要你手动带上。

> ⚠️ 杀软或 SmartScreen 可能对 `.vbs` 提示 —— 它唯一的作用是把 cmd 的黑窗隐藏掉（`WScript.Shell.Run` 的窗口样式设 0）。不放心可以直接用 `start-codex-proxy.cmd`，代价是每次双击会闪一下黑窗。

### 免安装（直接在原地用）

不解压也行，双击 `scripts/start-codex-proxy.cmd` 即可；只是每次会闪一个黑窗，也没有桌面图标。

### 从源码开始

```powershell
git clone https://github.com/gdSHAY/codex-connect-fix.git
cd codex-connect-fix
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-shortcut.ps1
```

### 卸载

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-shortcut.ps1 -Uninstall
```

只会删掉 `%APPDATA%\Codex-launcher\` 和桌面快捷方式，不动 Codex 本身，也不动任何系统设置。

## ✨ 症状对照表

先对照症状，不要盲目装。**「能不能解决」这一列是本工具的真实边界**：

| 你遇到的情况 | 能解决吗 | 为什么 |
| --- | --- | --- |
| Codex 一直转圈、提示网络错误，但浏览器能上外网 | ✅ | 典型表现：Codex 进程没拿到代理变量 |
| Codex 反复重连、远程 / 联网能力不可用 | ✅ | 同上 —— 本工具做的是让进程树带上代理 |
| 商店更新后，原来的启动快捷方式双击报「找不到文件」 | ✅ | 原版把带版本号的目录写死在脚本里，本版运行时解析 |
| 每次启动都闪一下黑窗，看着像报错 | ✅ | `.vbs` 包装器把窗口样式设为隐藏 |
| 快捷方式图标变成白纸 | ✅ | 图标复制到本地，不指向会被更新的安装目录 |
| 你根本没有本地代理（没开 Clash 之类的） | ❌ | 本工具**不含代理**，它只是把地址告诉 Codex |
| Codex 已经在运行，你才双击快捷方式 | ❌ | 环境变量不会注入到已存在的进程树，必须先完全退出 |
| 用的是自己装的 Codex CLI（非商店版） | ❌ | 本工具只处理包名为 `OpenAI.Codex` 的商店应用 |
| 你把代理换成了非 HTTP 协议（如 SOCKS-only） | ❌ | 注入的是 `http://` 形式的环境变量 |

## ⚙️ 三步开始用

1. **先启动代理**：打开 Clash / FlClash，确认本地 HTTP 端口在监听（默认 `7890`）
2. **安装一次**：跑上面的 `install-shortcut.ps1`
3. **以后每次**：双击桌面「启动 Codex 代理」，Codex 起来就能连

**支持的调用方式**

| 方式 | 命令 | 用途 |
| --- | --- | --- |
| 桌面快捷方式 | 双击 | 日常使用，静默启动 |
| 体检模式 | `start-codex-proxy.cmd --check` | 连不上时先跑这个，它会告诉你卡在哪一步 |
| 直接跑核心逻辑 | `start-codex-proxy.ps1 -Check` | 同上，控制台输出，便于贴给别人看 |

## ⚠️ 前提条件与能力边界（重要）

> 这一节是本仓库最值得读的部分。它明确写出**做不到什么**，比列举功能更能说明它到底是什么。

### 1. 你必须自备本地代理

本工具只做一件事：把一个已经存在的本地代理地址写进 Codex 进程的环境变量。它**不提供**代理、不内置任何节点、不修改任何系统的代理设置。

代理没在监听时，启动器会直接弹窗告诉你（而不是静默启动一个注定连不上的 Codex）：

```text
本地代理 http://127.0.0.1:7890 没有在监听。

请先启动 Clash / FlClash 并确认端口 7890 已开启，再启动 Codex。
```

### 2. 必须先完全退出 Codex

环境变量是**进程创建时继承**的，一个已经在跑的进程不会因为你双击了快捷方式就改掉自己的环境。所以正确顺序永远是：**完全退出 Codex → 双击快捷方式**。

体检输出里专门留了 `已注入` 一行，就是让你在启动前确认这件事。

### 3. 只影响这一棵进程树，不碰系统环境

启动器在 cmd 里用 `setlocal` 设变量，只对本次子进程有效，退出即消失。不写注册表、不调 `setx`、不改「Internet 选项」里的系统代理。因此：

- 不影响浏览器、不影响其它任何软件；
- 关掉启动器的窗口（或它自己退出）后，系统环境里查不到这些变量。

### 4. 商店包版本目录会变 —— 这是本仓库存在的主要原因

原始版本的启动器把路径写死成带版本号的目录：

```text
C:\Program Files\WindowsApps\OpenAI.Codex_26.908.4834.0_x64__2p2nqsd0c76g0\app\ChatGPT.exe
```

**实测记录（2026-10）**：写死时的版本是 `26.908.4834.0`，到本次核对时已变成 `26.928.3736.0` —— 目录名确实换了，原来那个写死的启动方式在商店更新后必然报「找不到文件」，而用户往往不知道是自己脚本过期了。

本版改为运行时解析：

```powershell
$pkg = Get-AppxPackage -Name 'OpenAI.Codex' | Select-Object -First 1
$exe = Join-Path $pkg.InstallLocation 'app\ChatGPT.exe'
```

并且加了一层兜底：万一将来商店包内部结构再变、app\ChatGPT.exe 不在了，会在安装目录里递归搜同名可执行文件；再找不到就弹窗并把安装目录打出来，方便提 Issue。

### 5. 代理端口不是 7890 时，改一行

`start-codex-proxy.cmd` 里只有一行需要改：

```bat
if not defined CODEX_PROXY set "CODEX_PROXY=http://127.0.0.1:7890"
```

也可以不改文件，直接在启动前设好环境变量 `CODEX_PROXY`（例如 `set CODEX_PROXY=http://127.0.0.1:1080`），脚本会优先用它。

### 6. 为什么 `.cmd` 和 `.vbs` 里是英文注释

不是为了装样子，是一个踩过的坑：**cmd.exe 用 OEM 代码页（简体中文系统是 936）解析 `.cmd` 文件**。文件里若含 UTF-8 中文，某些字节序列会把后面的回车符（`CR`）当成双字节字符的第二个字节吃掉，导致**两行被拼成一行**、脚本报出莫名其妙的「不是内部或外部命令」。实测就是这么坏的。

所以：`.cmd` / `.vbs` 全 ASCII，所有中文提示统一放在 `.ps1` 里，而 `.ps1` 存为 **UTF-8 with BOM**（PowerShell 5.1 只有看到 BOM 才按 UTF-8 读，否则按 ANSI 读，中文会变乱码）。

### 7. 实测澄清（2026-10）

| 流传的说法 | 实测结果 |
| --- | --- |
| 「把系统代理一开，Codex 就自动走代理了」 | **不成立**。本机系统代理确实开着，但没有注入变量时 Codex 依然连不上，这正是本仓库的起点。 |
| 「商店应用没法通过环境变量控制」 | **不成立**。进程树的继承关系对商店应用一样有效，实测主进程与子进程都拿到了 `HTTPS_PROXY`。 |
| 「直接双击 .ps1 就能用」 | **看执行策略**。本机默认为 `Restricted`，不加 `-ExecutionPolicy Bypass` 会被拒绝执行。 |

## 🧱 技术栈

| | |
| --- | --- |
| 脚本语言 | Windows 批处理（cmd）+ PowerShell 5.1 + VBScript |
| 系统依赖 | 全部来自 Windows 10 / 11 自带组件，**无需安装任何第三方库** |
| 关键 API | `Get-AppxPackage`（解析商店包）、`Start-Process`（继承环境变量启动）、`Get-NetTCPConnection`（探端口）、`WScript.Shell.Run`（隐藏窗口） |
| 分发 | 单个 zip 走 GitHub Releases；二进制与图标不进 git 对象库 |
| 无 | 没有安装程序、没有服务、没有常驻进程、没有配置文件 |

## 🗂 项目结构

```text
scripts/install-shortcut.ps1    一键安装：复制文件 / 提取官方图标 / 建快捷方式（支持 -Uninstall）
scripts/start-codex-proxy.cmd   手动入口：设好 4 个代理变量，再调用下面的核心逻辑
scripts/start-codex-proxy.ps1   核心逻辑：解析当前商店版本 -> 体检 -> 启动 Codex
scripts/run-codex-hidden.vbs    隐藏黑窗的包装器，快捷方式指向它
docs/codex-app-icon.png         README 用的官方图标（从安装包提取）
```

## ❓ 常见问题

<details>
<summary><b>双击快捷方式后什么都没发生，Codex 没起来</b></summary>

先跑体检模式，它会直接告诉你卡在哪：

```powershell
%APPDATA%\Codex-launcher\start-codex-proxy.cmd --check
```

三种最常见的输出与含义：`没有找到微软商店版 Codex` → 没装或包名变了；`代理端口 : 7890 未监听` → 代理没开；`主程序 : ... 找不到 ChatGPT.exe` → 商店包内部结构变了，请提 Issue 并附上打印出来的安装目录。
</details>

<details>
<summary><b>Codex 起来了，但提示网络错误 / 一直转圈</b></summary>

按顺序排三件事：

1. **Codex 是不是先于快捷方式就在跑了？** 那就先完全退出（含托盘图标）再双击快捷方式；
2. **代理是不是只开了系统代理、没开允许局域网 / 没监听 127.0.0.1？** 用体检输出里的 `代理端口` 一行确认，它显示的是真实监听状态；
3. **代理是不是只支持 SOCKS？** 本工具注入的是 `http://` 形式的变量，纯 SOCKS 端口需要你在代理软件里打开 HTTP 混合端口。
</details>

<details>
<summary><b>商店更新 Codex 之后，需要重装这个启动器吗？</b></summary>

不需要重装，但要**重新执行一次安装脚本**，目的是把新版安装包里的官方图标重新提取一份（否则图标不会更新，功能不受影响）。启动逻辑本身是版本无关的，不用管。
</details>

<details>
<summary><b>我改了代理端口，要改几个地方？</b></summary>

只改一处：`%APPDATA%\Codex-launcher\start-codex-proxy.cmd` 里的 `CODEX_PROXY` 那一行。体检模式与启动都读同一个变量，改完直接生效。注意仓库里那份副本也建议一起改，否则下次重跑安装脚本会把旧值覆盖回来。
</details>

<details>
<summary><b>这个启动器会修改 Codex 的安装文件吗？</b></summary>

不会。它只做三件事：读注册清单拿到安装目录、在自己的进程里设 4 个环境变量、用 `Start-Process` 启动 Codex 主程序。**不写 Codex 的任何文件、不写注册表、不改系统代理设置。**
</details>

## 📄 合规与免责

- 本仓库与 OpenAI **无任何关联**，非官方项目。Codex、ChatGPT 及相关图标是 OpenAI 的商标与著作权财产；本仓库提取图标仅用于在快捷方式与文档中**识别该程序**，不作任何其它用途。
- 本工具**不修改 Codex 程序本体**，不绕过任何付费、鉴权或地区限制；它只在本机为进程注入代理环境变量 —— 代理从哪来、能不能用，完全取决于你自己。
- 请在使用前自行确认：你的网络环境、所使用代理服务的行为符合当地法律法规，以及符合 OpenAI 的服务条款。
- 脚本按「现状」提供，不附带任何担保。因使用本工具造成的网络配置变化、账号风险或其它后果，**由使用者自行承担**。

## 📮 联系

| | |
| --- | --- |
| 问题反馈 | [Issues](https://github.com/gdSHAY/codex-connect-fix/issues)（请附上 `--check` 的完整输出） |
| 仓库 | <https://github.com/gdSHAY/codex-connect-fix> |
| 相关项目 | [codex-sandbox-doctor](https://github.com/gdSHAY/codex-sandbox-doctor)：修复 Codex 沙箱「Windows 设置未完成」 |

## ⭐ Star 历史

<a href="https://star-history.com/#gdSHAY/codex-connect-fix&Timeline">
  <img src="https://api.star-history.com/svg?repos=gdSHAY/codex-connect-fix&type=Timeline" alt="Star History" width="620">
</a>

## 📄 许可

本仓库采用 **MIT License**，见 [LICENSE](./LICENSE)。你可以自由使用、修改与再分发；发行版（Releases 里的压缩包）与源码适用同一许可。

<div align="center">
<sub>本 README 采用「<b>简体中文</b> / <a href="./README.en.md">English</a>」双语，可用顶部链接切换。</sub>
</div>
