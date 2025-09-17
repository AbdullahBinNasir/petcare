@echo off
echo PetCare PM2 Management Scripts
echo =============================

:menu
echo.
echo Choose an option:
echo 1. Start PetCare Web App
echo 2. Stop PetCare Web App
echo 3. Restart PetCare Web App
echo 4. Check Status
echo 5. View Logs
echo 6. Monitor
echo 7. Save PM2 Configuration
echo 8. Delete PM2 Configuration
echo 9. Exit
echo.
set /p choice="Enter your choice (1-9): "

if "%choice%"=="1" goto start
if "%choice%"=="2" goto stop
if "%choice%"=="3" goto restart
if "%choice%"=="4" goto status
if "%choice%"=="5" goto logs
if "%choice%"=="6" goto monitor
if "%choice%"=="7" goto save
if "%choice%"=="8" goto delete
if "%choice%"=="9" goto exit

:start
echo Starting PetCare Web App...
pm2 start ecosystem.config.js
goto menu

:stop
echo Stopping PetCare Web App...
pm2 stop petcare-web
goto menu

:restart
echo Restarting PetCare Web App...
pm2 restart petcare-web
goto menu

:status
echo Checking PM2 Status...
pm2 status
pause
goto menu

:logs
echo Viewing Logs...
pm2 logs petcare-web
goto menu

:monitor
echo Opening PM2 Monitor...
pm2 monit
goto menu

:save
echo Saving PM2 Configuration...
pm2 save
echo PM2 configuration saved!
pause
goto menu

:delete
echo Deleting PM2 Configuration...
pm2 delete petcare-web
echo PetCare Web App deleted from PM2!
pause
goto menu

:exit
echo Goodbye!
exit
