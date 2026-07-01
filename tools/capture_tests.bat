@echo off
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0capture_tests.ps1" %*
