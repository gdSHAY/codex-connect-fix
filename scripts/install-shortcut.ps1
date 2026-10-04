<#
  Codex 桌面版 · 一键安装（复制脚本 + 提取官方图标 + 建桌面快捷方式）

  用法（在本文件所在目录）：
      powershell -NoProfile -ExecutionPolicy Bypass -File .\install-shortcut.ps1

  做的事：
      1) 把 3 个脚本复制到 %APPDATA%\Codex-launcher\
      2) 从 Codex 安装包里提取官方图标 icon-chatgpt.ico -> codex.ico
         ★ 为什么要复制出来：快捷方式若直接指向商店包里的图标，
           商店一更新换了目录，图标就会失效（变成白纸）。
      3) 在桌面创建「启动 Codex 代理」快捷方式，指向 wscript.exe

  卸载：
      powershell -NoProfile -ExecutionPolicy Bypass -File .\install-shortcut.ps1 -Uninstall
      （删掉 %APPDATA%\Codex-launcher\ 与桌面快捷方式，不留其它痕迹）
#>
[CmdletBinding()]
param(
    [switch]$Uninstall,
    # 快捷方式显示名，想改中文名就传这个参数
    [string]$ShortcutName = '启动 Codex 代理'
)

$ErrorActionPreference = 'Stop'

$here       = Split-Path -Parent $MyInvocation.MyCommand.Path
$targetDir  = Join-Path $env:APPDATA 'Codex-launcher'
$desktop    = [Environment]::GetFolderPath('Desktop')
$lnkPath    = Join-Path $desktop ($ShortcutName + '.lnk')
$wscriptExe = Join-Path $env:SystemRoot 'System32\wscript.exe'

function Write-Step([string]$Text)  { Write-Host "  $Text" -ForegroundColor Cyan }
function Write-Ok([string]$Text)    { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-Warn([string]$Text)  { Write-Host "  [!!] $Text" -ForegroundColor Yellow }

# ---------------------------------------------------------------------------
# 卸载
# ---------------------------------------------------------------------------
if ($Uninstall) {
    Write-Host ''
    Write-Host '=== 卸载 Codex 代理启动器 ===' -ForegroundColor Cyan
    if (Test-Path -LiteralPath $lnkPath) {
        Remove-Item -LiteralPath $lnkPath -Force
        Write-Ok "已删除快捷方式：$lnkPath"
    } else {
        Write-Warn "快捷方式不存在：$lnkPath"
    }
    if (Test-Path -LiteralPath $targetDir) {
        Remove-Item -LiteralPath $targetDir -Recurse -Force
        Write-Ok "已删除安装目录：$targetDir"
    } else {
        Write-Warn "安装目录不存在：$targetDir"
    }
    Write-Host ''
    Write-Host '卸载完成。' -ForegroundColor Green
    exit 0
}

# ---------------------------------------------------------------------------
# 安装
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '=== 安装 Codex 代理启动器 ===' -ForegroundColor Cyan
Write-Host ''

# 1) 源文件齐不齐
$sources = 'start-codex-proxy.cmd', 'start-codex-proxy.ps1', 'run-codex-hidden.vbs'
$missing = @($sources | Where-Object { -not (Test-Path -LiteralPath (Join-Path $here $_)) })
if ($missing.Count -gt 0) {
    Write-Warn ("缺少源文件：{0}" -f ($missing -join ', '))
    Write-Warn '请确认本脚本与那 3 个脚本放在同一个目录里。'
    exit 1
}

# 2) 复制脚本
New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
foreach ($name in $sources) {
    Copy-Item -LiteralPath (Join-Path $here $name) -Destination (Join-Path $targetDir $name) -Force
}
Write-Ok "脚本已复制到 $targetDir"

# 3) 从 Codex 安装包提取官方图标（复制出来才不会随商店更新失效）
$pkg = Get-AppxPackage -Name 'OpenAI.Codex' -ErrorAction SilentlyContinue | Select-Object -First 1
$iconDst = Join-Path $targetDir 'codex.ico'
if ($pkg) {
    $iconCandidates = @(
        (Join-Path $pkg.InstallLocation 'app\resources\icon-chatgpt.ico'),
        (Join-Path $pkg.InstallLocation 'app\resources\chatgpt-app-dark.ico')
    )
    $iconSrc = $iconCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ($iconSrc) {
        Copy-Item -LiteralPath $iconSrc -Destination $iconDst -Force
        Write-Ok ("已提取官方图标：{0}（{1:N0} 字节）" -f (Split-Path -Leaf $iconSrc), (Get-Item -LiteralPath $iconDst).Length)
    } else {
        Write-Warn '在 Codex 安装包里没找到 .ico，快捷方式将使用 wscript 的默认图标。'
    }
} else {
    Write-Warn '没检测到商店版 Codex，跳过图标提取（不影响脚本本身可用）。'
}

# 4) 建桌面快捷方式
$shell = New-Object -ComObject WScript.Shell
$lnk = $shell.CreateShortcut($lnkPath)
$lnk.TargetPath       = $wscriptExe
$lnk.Arguments        = '"' + (Join-Path $targetDir 'run-codex-hidden.vbs') + '"'
$lnk.WorkingDirectory = $targetDir
$lnk.Description      = '带本地代理启动 Codex 桌面版（只影响该进程树）'
if (Test-Path -LiteralPath $iconDst) { $lnk.IconLocation = $iconDst + ',0' }
$lnk.Save()
Write-Ok "已创建桌面快捷方式：$ShortcutName.lnk"

Write-Host ''
Write-Host '安装完成，用法：' -ForegroundColor Green
Write-Host '  1) 先启动 Clash / FlClash，确认本地代理端口在监听（默认 7890）'
Write-Host '  2) 双击桌面「' + $ShortcutName + '」——不会有黑窗，Codex 直接起来'
Write-Host '  3) 若 Codex 已在运行，请先完全退出再从这个快捷方式启动，否则代理注入不进去'
Write-Host ''
Write-Host '体检命令（只检查、不启动）：' -ForegroundColor Cyan
Write-Host ('  ' + (Join-Path $targetDir 'start-codex-proxy.cmd') + ' --check')
Write-Host ''
exit 0
