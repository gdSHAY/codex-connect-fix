<#
  Codex 连接修复 · 方案 B：把代理写进「用户级」环境变量
  ==========================================================================
  什么时候需要它
  --------------
  手机远程连接电脑、以及 Codex 的远程（remote）能力，用的是 Codex 的
  **后台进程**。后台进程不是从方案 A 的启动脚本拉起的，继承不到那份
  进程级变量 —— 所以这类问题只有把变量写到用户级才能覆盖。

  代价（必须知道）
  ----------------
  用户级变量会被**当前用户下所有新启动的进程**继承，包括你并不想走代理的
  软件（git / pip / curl 等命令行工具尤其明显）。如果发现某个软件因此变慢
  或报错，用下面的 -Undo 撤销即可。

  用法（普通 PowerShell 即可，**不需要管理员**）
  ----------------------------------------------
      powershell -NoProfile -ExecutionPolicy Bypass -File .\set-user-proxy.ps1
      powershell -NoProfile -ExecutionPolicy Bypass -File .\set-user-proxy.ps1 -Status
      powershell -NoProfile -ExecutionPolicy Bypass -File .\set-user-proxy.ps1 -Undo

  为什么不用 setx
  ---------------
  setx 有 1024 字符截断、且超过长度会**静默失败**；这里统一用
  [Environment]::SetEnvironmentVariable(..., 'User')，它写的是注册表里
  HKCU\Environment，语义与「环境变量」对话框里点「新建」完全一致。

  ⚠️ 改完必须**完全退出 Codex 再重启**才生效 —— 已经跑着的进程不会回头读环境变量。
#>
[CmdletBinding()]
param(
    # 代理地址；端口不同就改这里
    [string]$Proxy = 'http://127.0.0.1:7890',
    # 本机回环直连，不要走代理
    [string]$NoProxy = 'localhost,127.0.0.1,::1',
    # 撤销：删掉本脚本写入的用户级变量
    [switch]$Undo,
    # 只查看当前状态，不做任何修改
    [switch]$Status
)

$ErrorActionPreference = 'Stop'

$names = 'HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY', 'NO_PROXY'

function Show-Status {
    Write-Host ''
    Write-Host '=== 当前「用户级」代理环境变量 ===' -ForegroundColor Cyan
    $any = $false
    foreach ($name in $names) {
        $user  = [Environment]::GetEnvironmentVariable($name, 'User')
        $proc  = [Environment]::GetEnvironmentVariable($name, 'Process')
        if ($user) { $any = $true }
        $u = if ($user) { $user } else { '(未设置)' }
        $p = if ($proc) { $proc } else { '(未设置)' }
        Write-Host ("{0,-12} 用户级={1}" -f $name, $u)
        Write-Host ("{0,-12} 本进程={1}" -f '', $p)
    }
    Write-Host ''
    if (-not $any) {
        $hint = '未设置任何用户级代理变量 —— 若远程连接失败，可以跑本脚本设置。'
        Write-Host $hint -ForegroundColor Yellow
    } else {
        $hint = '已设置。注意：改动只对**之后新启动**的进程生效，Codex 必须完全退出后重启。'
        Write-Host $hint -ForegroundColor Green
    }
}

if ($Status) {
    Show-Status
    exit 0
}

if ($Undo) {
    Write-Host ''
    Write-Host '=== 撤销：删除用户级代理变量 ===' -ForegroundColor Cyan
    foreach ($name in $names) {
        [Environment]::SetEnvironmentVariable($name, $null, 'User')
        Write-Host ("  已删除 {0}" -f $name) -ForegroundColor Green
    }
    Write-Host ''
    Write-Host '完成。' -ForegroundColor Green
    Show-Status
    exit 0
}

Write-Host ''
Write-Host '=== 设置用户级代理环境变量 ===' -ForegroundColor Cyan
Write-Host ''

# 顺手提醒一次：代理端口没监听的话，设了也白设
$port = 7890
if ($Proxy -match ':(\d+)') { $port = [int]$Matches[1] }
$listener = $null
try {
    $listener = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue |
                Select-Object -First 1
} catch { }
if ($listener) {
    Write-Host ("代理端口 {0} 正在监听（PID {1}）" -f $port, $listener.OwningProcess) -ForegroundColor Green
} else {
    $msg = "代理端口 $port 现在没有在监听。变量会照常写入，但在你启动代理软件之前 Codex 依然连不上。"
    Write-Host $msg -ForegroundColor Yellow
}

foreach ($name in 'HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY') {
    [Environment]::SetEnvironmentVariable($name, $Proxy, 'User')
    Write-Host ("  已写入 {0} = {1}" -f $name, $Proxy) -ForegroundColor Green
}
[Environment]::SetEnvironmentVariable('NO_PROXY', $NoProxy, 'User')
Write-Host ("  已写入 {0} = {1}" -f 'NO_PROXY', $NoProxy) -ForegroundColor Green

Write-Host ''
Write-Host '完成。' -ForegroundColor Green
Show-Status
Write-Host ''
Write-Host '下一步：' -ForegroundColor Cyan
Write-Host '  1) 完全退出 Codex（含托盘图标），再重新打开 —— 已运行的进程不会回头读环境变量'
Write-Host '  2) 若某个命令行工具（git / pip / curl）因此变慢或报错，跑本脚本加 -Undo 撤销'
exit 0
