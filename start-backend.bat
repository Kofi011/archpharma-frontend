@echo off
title ArchPharma Backend
cd /d "%~dp0backend"
echo ====================================================
echo Starting ArchPharma NestJS Backend...
echo ====================================================
npm.cmd run start:dev
pause
