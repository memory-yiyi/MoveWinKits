<# Runtime Checks #>
Write-Host 'Check if it meets the running conditions'
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'ERROR: Run with non administrator privileges.' -ForegroundColor Red
    exit
}
if (@(Get-Process 'devenv' -ErrorAction SilentlyContinue).Count -ne 0) {
    Write-Host 'ERROR: Please close Visual Studio.' -ForegroundColor Red
    exit
}
Write-Host 'OK' -ForegroundColor Green

<# Initialize global variables #>
Set-Location $PSScriptRoot
[string]$Source = (Read-Host '     Source Path')
[string]$Destination = (Read-Host 'Destination Path')
[string]$backupFile = "BackupLog$(Get-Date -Format 'yyMMddhhmmss').reg"
[string]$outFile = "ChangeLog$(Get-Date -Format 'yyMMddhhmmss').reg"
[string[]]$SD = @()
@($Source, $Destination) | ForEach-Object {
    $str = $_
    if ($str -notmatch '\\$') { $str += '\' }
    $str += 'Windows Kits'
    $SD += $str.Replace('\', '\\')
}

<# Getting local information #>
& {
    if (-not ((Test-Path $Source) -and (Test-Path $Destination))) {
        Write-Host 'ERROR: Please enter the correct path.' -ForegroundColor Red
        exit
    }
    if (-not (Test-Path tmp)) { New-Item tmp -ItemType Directory }
    else { Remove-Item tmp\* }

    Write-Host 'Getting system registry'
    [int[]]$proId = @()
    @('HKLM', 'HKCU', 'HKCR', 'HKU', 'HKCC') | ForEach-Object {  
        $proId += (Start-Process $env:ComSpec "/c ""reg export $_ tmp\$_.reg""" -WorkingDirectory $PWD -WindowStyle Hidden -PassThru).Id
    }
    Wait-Process $proId
    Write-Host 'OK' -ForegroundColor Green
}

<# Extract key registry #>
& {
    [string]$str = ''
    [string[]]$strArrB = @()
    [string[]]$strArr = @()
    [bool]$bodyFind = $false

    Write-Host 'Extract key registry'
    "Windows Registry Editor Version 5.00`n" | Out-File $backupFile -Encoding unicode
    "Windows Registry Editor Version 5.00`n" | Out-File $outFile -Encoding unicode
    Get-ChildItem tmp\*.reg | ForEach-Object {
        foreach ($s in [System.IO.File]::ReadLines($_.FullName, [System.Text.Encoding]::Unicode)) {
            $str = $s
            if ($str[0] -eq '[') {
                if ($bodyFind) {
                    $bodyFind = $false
                    $strArrB += ''
                    $strArrB | Out-File $backupFile -Encoding unicode -Append 
                    $strArr += ''
                    $strArr | Out-File $outFile -Encoding unicode -Append 
                }      
                $strArrB = @()
                $strArrB += $str
                $strArr = @()
                $strArr += $str
            }
            else {
                if ($str -like "*$($SD[0])*") {
                    $bodyFind = $true
                    $strArrB += $str
                    $strArr += $str.Replace($SD[0], $SD[1])
                }
            }
        }
        # Prevent missing the last piece of data
        if ($bodyFind) {
            $strArrB | Out-File $backupFile -Encoding unicode -Append 
            $strArr | Out-File $outFile -Encoding unicode -Append 
        }
    }
    if ((Get-Item $outFile).Length -le 76) {
        Write-Host 'ERROR: Extraction failed, please try again' -ForegroundColor Red
        exit
    }
    Write-Host 'OK' -ForegroundColor Green
}

<# Move and Import #>
& {
    Write-Host 'Try to move directory'
    foreach ($i in 0..1) { $SD[$i] = $SD[$i].Replace('\\', '\') }
    if (Test-Path $SD[0]) {
        Move-Item $SD[0] $SD[1]
        Write-Host 'OK' -ForegroundColor Green
    }
    else {
        Write-Host "ERROR: Not found '$($SD[0])', Please manually move the directory" -ForegroundColor Red
    }

    Write-Host 'Import reorganization registry' -ForegroundColor Yellow
    reg import $outFile
    Remove-Item tmp -Recurse
}
