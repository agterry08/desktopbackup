@echo off

cd C:\itaotemp\desktopbackupscripts\PS1Files
powershell -WindowStyle Hidden -NoLogo -NoProfile -command "& { . .\desktopbackup.ps1; run-fullbackup }" 