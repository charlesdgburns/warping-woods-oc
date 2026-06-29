@echo off
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0capture_errors.ps1" %*
