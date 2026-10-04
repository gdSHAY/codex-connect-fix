<#
  Codex 桌面版 · 按应用代理启动器（核心逻辑）

  由 start-codex-proxy.cmd 调用 —— 代理环境变量在 cmd 里设置好，
  本脚本只负责「解析当前商店版本 -> 体检 -> 启动主程序」。

  单独运行（排查）：
      powershell -NoProfile -ExecutionPolicy Bypass -File .\start-codex-proxy.ps1 -Check
#>
[CmdletBinding()]
param(
    # 只体检、不启动（等同于 cmd 的 --check）
    [switch]$Check
)

$ErrorActionPreference = 'Stop'

if ($env:CODEX_LAUNCHER_CHECK -eq '1') { $Check = $true }

function Show-Popup {
    param([string]$Text, [int]$Icon = 48)   # 48 = 警告图标
    try {
        (New-Object -ComObject WScript.Shell).Popup($Text, 0, 'Codex 代理启动器', $Icon) | Out-Null
    } catch {
        Write-Host $Text
    }
}

function Fail {
    param([string]$Text)
    Show-Popup $Text
    exit 1
}

# ---------------------------------------------------------------------------
# 1. 解析微软商店版 Codex 的当前安装路径（这一步让启动器与版本解耦）
# ---------------------------------------------------------------------------
$pkg = Get-AppxPackage -Name 'OpenAI.Codex' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $pkg) {
    Fail "没有找到微软商店版 Codex（包名 OpenAI.Codex）。`n`n请先在微软商店安装 Codex 桌面版，再运行本启动器。"
}

$installDir = $pkg.InstallLocation
$exe = Join-Path $installDir 'app\ChatGPT.exe'
if (-not (Test-Path -LiteralPath $exe)) {
    # 兜底：商店包内部结构若在将来变动，退化为全目录搜索
    $found = Get-ChildItem -LiteralPath $installDir -Filter 'ChatGPT.exe' -Recurse -ErrorAction SilentlyContinue |
             Select-Object -First 1
    if ($found) { $exe = $found.FullName }
}
if (-not (Test-Path -LiteralPath $exe)) {
    Fail "已定位到 Codex 安装目录，但里面找不到 ChatGPT.exe：`n$installDir`n`n可能是商店包内部结构变了，请到仓库提 Issue 并附上这个路径。"
}

# ---------------------------------------------------------------------------
# 2. 体检：代理变量在不在、代理端口通不通
# ---------------------------------------------------------------------------
$proxy = $env:CODEX_PROXY
if (-not $proxy) { $proxy = 'http://127.0.0.1:7890' }

$port = 7890
if ($proxy -match ':(\d+)') { $port = [int]$Matches[1] }

$missingEnv = @()
foreach ($name in 'HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY', 'NO_PROXY') {
    if (-not [Environment]::GetEnvironmentVariable($name, 'Process')) { $missingEnv += $name }
}

$listener = $null
try {
    $listener = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue |
                Select-Object -First 1
} catch { }

Write-Host ''
Write-Host '=== Codex 代理启动器 · 体检 ===' -ForegroundColor Cyan
Write-Host ("安装版本 : {0}" -f $pkg.Version)
Write-Host ("安装目录 : {0}" -f $installDir)
Write-Host ("主程序   : {0}" -f $exe)
Write-Host ("代理地址 : {0}" -f $proxy)
if ($listener) {
    Write-Host ("代理端口 : {0} 正在监听（PID {1}）" -f $port, $listener.OwningProcess) -ForegroundColor Green
} else {
    Write-Host ("代理端口 : {0} 未监听 —— Codex 很可能连不上" -f $port) -ForegroundColor Yellow
}
if ($missingEnv.Count -eq 0) {
    Write-Host ("已注入   : HTTP_PROXY / HTTPS_PROXY / ALL_PROXY / NO_PROXY") -ForegroundColor Green
} else {
    Write-Host ("未注入   : {0}" -f ($missingEnv -join ', ')) -ForegroundColor Yellow
    Write-Host '           请通过 start-codex-proxy.cmd（或桌面快捷方式）启动，它会先设好代理变量。'
}
Write-Host ("隐含变量 : NO_PROXY={0}" -f $env:NO_PROXY)
Write-Host ''

# 代理没在监听：这是最常见的失败原因，直接告诉用户，别让他对着「连不上」猜
if (-not $listener -and -not $Check) {
    Show-Popup "本地代理 $proxy 没有在监听。`n`n请先启动 Clash / FlClash 并确认端口 $port 已开启，再启动 Codex。`n`n（只做了体检、未启动 Codex。想跳过这个提示请自行承担连不上的后果。）"
    exit 2
}

if ($Check) {
    Write-Host '体检模式：未启动 Codex。' -ForegroundColor Cyan
    exit 0
}

# ---------------------------------------------------------------------------
# 3. 启动 Codex —— 它继承上面已在进程里设好的代理变量
# ---------------------------------------------------------------------------
Start-Process -FilePath $exe
Write-Host '已启动 Codex（继承本次注入的代理设置）。' -ForegroundColor Green
exit 0
