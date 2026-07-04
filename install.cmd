@echo off
REM Nimbus Installer - Windows
REM Usage: curl -fsSL https://nimbus.yoodule.com/install.cmd -o install.cmd && install.cmd
REM   Pin a version:  set NIMBUS_VERSION=vX.Y.Z  (before running install.cmd)
echo Installing Nimbus for Windows...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; if ($env:NIMBUS_VERSION) { Write-Host \"Using NIMBUS_VERSION=$env:NIMBUS_VERSION\" }; irm https://nimbus.yoodule.com/install.ps1 | iex"
