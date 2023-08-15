<# Initialize global variables #>
Set-Location $PSScriptRoot
[string]$Source = (Read-Host '     Source Path')
[string]$Destination = (Read-Host 'Destination Path')

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
