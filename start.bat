@echo off
title TFS 7.72 Server
cd /d "%~dp0"

REM Auto-extract world.otbm from the zipped tracked copy if it isn't on disk.
if not exist "data\world\world.otbm" (
	if exist "data\world\world.otbm.zip" (
		echo Extracting data\world\world.otbm from zip...
		powershell -NoProfile -Command "Expand-Archive -Path 'data\world\world.otbm.zip' -DestinationPath 'data\world' -Force"
	) else (
		echo ERROR: data\world\world.otbm.zip not found. Cannot start without a map.
		pause
		exit /b 1
	)
)

".\build\RelWithDebInfo\tfs.exe"
echo.
echo ============================================================
echo Server finalizado. Pressione qualquer tecla para fechar.
echo ============================================================
pause >nul
