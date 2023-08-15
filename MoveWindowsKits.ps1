<# Initialize global variables #>
Set-Location $PSScriptRoot
[string]$Source = (Read-Host '     Source Path')
[string]$Destination = (Read-Host 'Destination Path')
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
    [string[]]$strArr = @()
    [bool]$bodyFind = $false
    [string]$outFile = "ChangeLog$(Get-Date -Format 'yyMMddhhmmss').reg"

    Write-Host 'Extract key registry'
    "Windows Registry Editor Version 5.00`n" | Out-File $outFile -Encoding unicode
    Get-ChildItem tmp\*.reg | ForEach-Object {
        foreach ($s in [System.IO.File]::ReadLines($_.FullName, [System.Text.Encoding]::Unicode)) {
            $str = $s
            if ($str[0] -eq '[') {
                if ($bodyFind) {
                    $bodyFind = $false
                    $strArr += ''
                    $strArr | Out-File $outFile -Encoding unicode -Append 
                }      
                $strArr = @()
                $strArr += $str
            }
            else {
                if ($str -like "*$($SD[0])*") {
                    $bodyFind = $true
                    $strArr += $str.Replace($SD[0], $SD[1])
                }
            }
        }
    }
    # Prevent missing the last piece of data
    if ($bodyFind) { $strArr | Out-File $outFile -Encoding unicode -Append }
    Write-Host 'OK' -ForegroundColor Green
}
