@echo off
title TFS 7.72 Server
cd /d "%~dp0"
".\build\RelWithDebInfo\tfs.exe"
echo.
echo ============================================================
echo Server finalizado. Pressione qualquer tecla para fechar.
echo ============================================================
pause >nul
