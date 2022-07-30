Set-Location $PSScriptRoot
[string]$Source = (Read-Host '     Source Path')
[string]$Destination = (Read-Host 'Destination Path')

& {
    if (Test-Path dat) {
        Write-Error "'dat' folder exists, please move or delete it."
        exit
    }
    if (-not ((Test-Path $Source) -and (Test-Path $Destination))) {
        Write-Error 'Please enter the correct path.'
        exit
    }
    New-Item dat -ItemType Directory | Out-Null
}

& {
    $i = 1
    $j = 11
    [int]$status = 0
    foreach ($item in @('HKLM', 'HKCU', 'HKCR', 'HKU', 'HKCC')) {
        $status = $i / 5 * 100
        Write-Progress -Activity 'Extracting local registry' -Status "$i/5" -PercentComplete $status
        reg export $item "dat\$j.reg" | Out-Null
        $i++
        $j++
    }
}

& {
    $i = 1
    [int]$status = 0
    $file = (Get-ChildItem dat\*.reg)
    $filenum = @($file).Count
    $file | ForEach-Object {
        $status = $i / $filenum * 100
        Write-Progress -Activity 'Code conversion in progress' -Status "$i/$filenum"-PercentComplete $status
        Get-Content $_.FullName | Out-File "dat\$i.reg" ascii
        Remove-Item $_.FullName
        $i++
    }
}

& {
    Write-Output 'Extract and import the key registry, and move the "Windows Kits" folder, please wait...'
    .\GetValuableReg.exe $Source $Destination
    if ((Get-Item dat\0.reg).Length -le 42) {

        Write-Error 'Registry extraction exception, please check whether the source path is correct.'
        exit
    }
    Get-Content dat\0.reg | Out-File dat\6.reg unicode
    reg import dat\6.reg
    Remove-Item dat -Force -Recurse
}