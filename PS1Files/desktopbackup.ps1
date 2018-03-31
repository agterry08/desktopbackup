

Function run-fullbackup {
$7zip = "C:\PSBACKUPSCRIPTS\x64\7za.exe"
$excludesfile = "C:\itaotemp\desktopbackupscripts\excludes.txt"
$includesfile = "C:\itaotemp\desktopbackupscripts\includes.txt"
$desktop = Get-Content C:\itaotemp\desktopbackupscripts\desktopbackuplocation.txt
$backupoutputpath = "$desktop\$env:computername\$env:username"
If(!(test-path $backupoutputpath))
{
      New-Item -ItemType Directory -Force -Path $backupoutputpath
}
Set-Content -Path C:\itaotemp\desktopbackupscripts\includes.txt -Value `
                                    "$env:USERPROFILE\*.ppt", `
                                    "$env:USERPROFILE\*.xls", `
                                    "$env:USERPROFILE\*.xlsx", `
                                    "$env:USERPROFILE\*.doc", `
                                    "$env:USERPROFILE\*.docx", `
                                    "$env:USERPROFILE\*.pdf", `
                                    "$env:USERPROFILE\*.qbw", `
                                    "$env:USERPROFILE\*.nk2"
Set-Content -Path C:\itaotemp\desktopbackupscripts\excludes.txt -Value `
                                    "$env:USERPROFILE\AppData\*", `
                                    "$env:USERPROFILE\.*", `
                                    "$env:USERPROFILE\One*", `
                                    "C:\Users\Public\*", `
                                    "C:\Users\Default\*", `
                                    "C:\Users\All Users\*", `
                                    "C:\Users\Default User\*"
$date = Get-Date -Format "yyyMMdd-hhmm"
$outputfile = "$backupoutputpath\backup-$date.7z"
$logfilename = [io.path]::GetFileNameWithoutExtension("$outputfile")
$logfile = "$backupoutputpath\backup-$date.log"
$7zipArgsfull = @(
    "a";   
    "-bb3";
    "-spf";                   
    "-t7z";                       
    "-mx=7";                      
    "-xr!thumbs.db";              
    "-xr!*.log";                  
    "-xr@`"`"$excludesFile`"`""; 
    "-ir@`"`"$includesFile`"`"";
    "$outputFile";                
)
$allfullBackups = Get-ChildItem -File -Path "$backupoutputpath\backup-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9].7z"
if ($allfullbackups -is [array] ) {
    [Array]:: Reverse($allfullBackups)
    $allfullBackups |  ForEach-Object {
        Write-Host "Deleting old full backup. File: $($_.FullName)"
        # Remove the matching log file.
        Remove-Item -LiteralPath ([System.IO.Path ]::ChangeExtension($_.FullName, ".log")) -ErrorAction SilentlyContinue
        $_
    } | Remove-Item
} 


& $7zip @7zipArgsfull | Tee-Object -LiteralPath $logFile
if ($LASTEXITCODE -gt 1) # Ignores warnings which use exit code 1.
{
    throw "7zip failed with exit code $LASTEXITCODE"
}

}
Function run-removefullbackups{
$desktop = Get-Content C:\itaotemp\desktopbackupscripts\desktopbackuplocation.txt
$backupoutputpath = "$desktop\$env:computername"
$allfullBackups = Get-ChildItem -File -Path "$backupoutputpath\backup-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9].7z"
if ($allfullbackups -is [array] ) {
    [Array]:: Reverse($allfullBackups)
    $allfullBackups |  ForEach-Object {
        Write-Host "Deleting old full backup. File: $($_.FullName)"
        # Remove the matching log file.
        Remove-Item -LiteralPath ([System.IO.Path ]::ChangeExtension($_.FullName, ".log")) -ErrorAction SilentlyContinue
        $_
    } | Remove-Item
} 
}
Function run-diffbackup {
$desktop = Get-Content C:\itaotemp\desktopbackupscripts\desktopbackuplocation.txt
$backupoutputpath = "$desktop\$env:computername\$env:username"
If(!(test-path $backupoutputpath))
{
      New-Item -ItemType Directory -Force -Path $backupoutputpath
}
$date = Get-Date -Format "yyyMMdd-hhmm"
$excludesfile = "C:\itaotemp\desktopbackupscripts\excludes.txt"
$includesfile = "C:\itaotemp\desktopbackupscripts\includes.txt"
$7zip = "C:\itaotemp\PSBACKUPSCRIPTS\x64\7za.exe"
$fullBackup = Get-ChildItem -File -Path "$backupoutputpath\backup-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9].7z" | select -Last 1 -ExpandProperty FullName
if (-not ($fullBackup) -or -not (Test-Path $fullBackup -PathType Leaf)) {
    throw "No full backup was found. Must have a full backup before performing a differential."
}
$diffoutputfilename = [io.path]::GetFileNameWithoutExtension($fullbackup)
$diffoutputfile = "$backupoutputpath\$diffoutputfilename-diff-$date.7z"
$logfilename = [io.path]::GetFileNameWithoutExtension($diffoutputfile)
$logfile = "$backupoutputpath\$logfilename.log"
$7zipArgsdiff = @(
    "u";                                    
    "$fullBackup";                      
    "-t7z";
    "-spf";
    "-stl";
    "-mx=7";
    "-xr!thumbs.db";
    "-xr!*.log";
    "-xr-@`"`"$excludesFile`"`"";
    "-ir-@`"`"$includesFile`"`"";
    "-bb3";
    "-u-";                                  
    "-up0q3r2x2y2z0w2!`"`"$diffoutputfile`"`"";
)
$allDiffBackups = Get-ChildItem -File -Path "$backupOutputPath\backup-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]-diff-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9].7z"
if ($allDiffBackups -is [array] ) {
    [Array]:: Reverse($allDiffBackups)
    $allDiffBackups | select -Skip 1 | ForEach-Object {
        Write-Host "Deleting old differential backup. File: $($_.FullName)"
        # Remove the matching log file.
        Remove-Item -LiteralPath ([System.IO.Path ]::ChangeExtension($_.FullName, ".log")) -ErrorAction SilentlyContinue
        $_
    } | Remove-Item
} 
& $7zip @7zipArgsdiff | Tee-Object -LiteralPath $logFile
if ($LASTEXITCODE -gt 1) # Ignores warnings which use exit code 1.
{
    throw "7zip failed with exit code $LASTEXITCODE"
}
}