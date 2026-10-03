@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Thin Aptm - NovaGate Flow Veo
start "" pythonw novagate_app.py
