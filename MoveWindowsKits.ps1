class RuntimeCheck {
    <# 检查管理员权限 #>
    hidden static [void] AdministratorCheck() {
        if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Host '错误：没有管理员权限' -ForegroundColor Red
            exit
        }
    }
    <# 检查相关程序运行状态 #>
    hidden static [void] ProgramCheck() {
        if (@(Get-Process 'devenv', 'blend' -ErrorAction SilentlyContinue).Count -ne 0) {
            Write-Host '错误：Visual Studio 或 Blend 正在运行' -ForegroundColor Red
            exit
        }
    }
    [void] static Execute() {
        Write-Host '检查代码运行环境'
        [RuntimeCheck]::AdministratorCheck()
        [RuntimeCheck]::ProgramCheck()
        Write-Host '完成' -ForegroundColor Green
    }
}

class FilePath {
    hidden [string]$_path
    hidden [string]$_path2

    static [hashtable[]] $MemberDefinitions = @(
        @{
            MemberType  = 'ScriptProperty'
            MemberName  = 'Path'
            Value       = { $this._path }
            SecondValue = {
                $ProposedValue = $args[0]
                if (Test-Path $ProposedValue) {
                    if ($ProposedValue -notmatch '\\$') { $ProposedValue += '\' }
                    $ProposedValue += 'Windows Kits'
                    $this._path = $ProposedValue
                    $this._path2 = $ProposedValue.Replace('\', '\\')
                }
                else { throw }
            }
        }
        @{
            MemberType = 'ScriptProperty'
            MemberName = 'RegPath'
            Value      = { $this._path2 }
        }
    )

    static FilePath() {
        $TypeName = [FilePath].Name
        foreach ($Definition in [FilePath]::MemberDefinitions) {
            Update-TypeData -TypeName $TypeName @Definition
        }
    }
}

class Main {
    [FilePath]$Source = [FilePath]::new()
    [FilePath]$Destination = [FilePath]::new()
    [string]$BackupPath = "BackupLog$(Get-Date -Format 'yyMMddhhmmss').reg"
    [string]$OutPath = "ChangeLog$(Get-Date -Format 'yyMMddhhmmss').reg"

    static [void] Start() {
        [RuntimeCheck]::Execute()
        Set-Location $PSScriptRoot
        if (-not (Test-Path tmp)) { New-Item tmp -ItemType Directory }
        else { Remove-Item tmp\* }
        
        [Main]$info = [Main]::new()
        try {
            $info.Source.Path = (Read-Host '  原路径')
            $info.Destination.Path = (Read-Host '目标路径')
        }
        catch {
            Write-Host '错误：输入的文件路径不合法' -ForegroundColor Red
            exit
        }
        $info.GetReg()
        $info.ExtractReg()
        $info.ImportReg()
        $info.MoveFile()
    }

    [void] GetReg() {
        Write-Host '获取系统注册表中，请等待'
        [int[]]$proId = @()
        @('HKLM', 'HKCU', 'HKCR', 'HKU', 'HKCC') | ForEach-Object {  
            $proId += (Start-Process $env:ComSpec "/c ""reg export $_ tmp\$_.reg""" -WorkingDirectory $PWD -WindowStyle Hidden -PassThru).Id
        }
        Wait-Process $proId
        Write-Host '完成' -ForegroundColor Green
    }

    [void] ExtractReg() {
        [string]$str = ''
        [string[]]$strArr = @()
        [string[]]$strArrB = @()
        [bool]$bodyFind = $false

        Write-Host '提取关键注册表中，请等待'
        "Windows Registry Editor Version 5.00`n" | Out-File $this.OutPath -Encoding unicode
        "Windows Registry Editor Version 5.00`n" | Out-File $this.BackupPath -Encoding unicode
        Get-ChildItem tmp\*.reg | ForEach-Object {
            foreach ($s in [System.IO.File]::ReadLines($_.FullName, [System.Text.Encoding]::Unicode)) {
                $str = $s
                if ($str[0] -eq '[') {
                    if ($bodyFind) {
                        $bodyFind = $false
                        $strArr += ''
                        $strArr | Out-File $this.OutPath -Encoding unicode -Append
                        $strArrB += ''
                        $strArrB | Out-File $this.BackupPath -Encoding unicode -Append
                    }
                    $strArr = @()
                    $strArr += $str
                    $strArrB = @()
                    $strArrB += $str
                }
                else {
                    if ($str -like "*$($this.Source.RegPath)*") {
                        $bodyFind = $true
                        $strArr += $str.Replace($this.Source.RegPath, $this.Destination.RegPath)
                        $strArrB += $str
                    }
                    elseif ($str -like "*$($this.Source.Path)*") {
                        $bodyFind = $true
                        $strArr += $str.Replace($this.Source.Path, $this.Destination.RegPath)
                        $strArrB += $str.Replace($this.Source.Path, $this.Source.RegPath)
                    }
                }
            }
        }
        if ($bodyFind) {
            # 防止遗漏数据
            $strArr | Out-File $this.OutPath -Encoding unicode -Append
            $strArrB | Out-File $this.BackupPath -Encoding unicode -Append
        }
        if ((Get-Item $this.OutPath).Length -le 88) {
            Write-Host '错误：提取失败，请重试' -ForegroundColor Red
            Remove-Item $this.OutPath, $this.BackupPath
            exit
        }
        Write-Host '完成' -ForegroundColor Green
    }

    [void] ImportReg() {
        Write-Host '导入重组注册表'
        try {
            Start-Process "$env:windir\regedit.exe" -ArgumentList "/s $($this.OutPath)" -Wait -PassThru
        }
        catch {
            Write-Host '错误：导入失败，请重试' -ForegroundColor Red
            exit
        }
        Write-Host '完成' -ForegroundColor Green
    }

    [void] MoveFile() {
        Write-Host '移动 Windows Kits 文件夹中，请等待'
        if (Test-Path $this.Source.Path) {
            Move-Item $this.Source.Path $this.Destination.Path
            Write-Host '完成' -ForegroundColor Green
        }
        else {
            Write-Host "异常：未找到'$($this.Source.Path)'，请手动将文件夹移入目标位置" -ForegroundColor Red
        }
    }
}

[Main]::Start()
