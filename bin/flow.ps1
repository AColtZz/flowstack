param([string]$Action, [string]$Value)

$StackPort = "8888"
$PSScriptPath = Split-Path $MyInvocation.MyCommand.Path
$AppRoot = Split-Path $PSScriptPath -Parent

# Auto-locate Scoop Persist
$ScoopRoot = $PSScriptPath
for ($i=0; $i -lt 4; $i++) { $ScoopRoot = Split-Path $ScoopRoot -Parent }
$UserHtdocs = Join-Path $ScoopRoot "persist\flowstack\htdocs"

switch ($Action) {
    "up" {
        Write-Host ">>> FlowStack: Starting Services..." -ForegroundColor Cyan

        # Junction link to Persist
        $DashboardHtdocs = Join-Path $AppRoot "core\dashboard\htdocs"
        if (Test-Path $DashboardHtdocs) { Remove-Item $DashboardHtdocs -Recurse -Force }
        New-Item -ItemType Junction -Path $DashboardHtdocs -Target $UserHtdocs | Out-Null

        # Start PHP & MySQL
        $PhpDir = Split-Path (Get-Command php).Source
        $CustomIni = Join-Path $AppRoot "core\templates\php-stack.ini"

        Start-Process mysqld -ArgumentList "--console" -WindowStyle Hidden
        Start-Process php -ArgumentList "-S", "localhost:$StackPort", "-t", "`"$AppRoot\core\dashboard`"", "-c", "`"$CustomIni`"" -WindowStyle Hidden

        Write-Host ">>> FlowStack is LIVE at http://localhost:$StackPort" -ForegroundColor Green
        Start-Process "http://localhost:$StackPort"
    }

    "down" {
        Get-Process php, mysqld -ErrorAction SilentlyContinue | Stop-Process -Force
        Write-Host ">>> Services stopped." -ForegroundColor Red
    }

    "new" {
        & "$PSScriptPath\helpers\new-site.ps1" -InstallPath $UserHtdocs
    }

    Default {
        Write-Host "Usage: flow [up | down | new]" -ForegroundColor White
    }
}