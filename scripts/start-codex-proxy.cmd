@echo off
rem ===========================================================================
rem  Codex Desktop - per-app proxy launcher
rem
rem  What it does: injects local proxy environment variables into the Codex
rem  process tree started from here ONLY. No system-wide or user-wide env
rem  variable is modified.
rem
rem  Version independent: the Microsoft Store package path is resolved at run
rem  time via Get-AppxPackage, so Store updates never break this file.
rem
rem  Usage:
rem    Double click (or desktop shortcut)   start Codex silently
rem    Run with --check in a console        diagnose only, do not launch
rem
rem  NOTE: this file is deliberately ASCII-only. cmd.exe parses .cmd files using
rem  the OEM code page (e.g. 936 on zh-CN); UTF-8 non-ASCII bytes can swallow the
rem  following CR and merge two lines into one. All localized (Chinese) text
rem  lives in start-codex-proxy.ps1 instead, which is UTF-8 with BOM.
rem ===========================================================================
setlocal EnableExtensions

rem ---- Local proxy address. Clash / FlClash / Mihomo default to 7890. ----
rem      Change this one line if your port differs; CODEX_PROXY overrides it.
if not defined CODEX_PROXY set "CODEX_PROXY=http://127.0.0.1:7890"

set "HTTP_PROXY=%CODEX_PROXY%"
set "HTTPS_PROXY=%CODEX_PROXY%"
set "ALL_PROXY=%CODEX_PROXY%"
rem Keep loopback traffic off the proxy, otherwise Codex <-> local helpers
rem would take a detour through it.
set "NO_PROXY=localhost,127.0.0.1,::1"

if /i "%~1"=="--check" set "CODEX_LAUNCHER_CHECK=1"

rem The proxy variables MUST be set in this process before Codex is started -
rem the order matters, the child inherits them.
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PS%" set "PS=powershell"
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-codex-proxy.ps1"
set "RC=%ERRORLEVEL%"

endlocal & exit /b %RC%
