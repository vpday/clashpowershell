@echo off
rem mode con cols=80 lines=30
color f1
title ClashPowerShell

pushd %~dp0
if exist "%~dp0\App\cps\clashpowershell.ps1" (
    powershell -ExecutionPolicy Bypass -File "%~dp0\App\cps\clashpowershell.ps1"
)
