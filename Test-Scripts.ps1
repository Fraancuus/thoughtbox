# Quick test to verify PowerShell scripts have valid syntax
Write-Host "Testing PowerShell script syntax..." -ForegroundColor Cyan
Write-Host ""

$scripts = @(
    "Install-StartupTask.ps1",
    "Uninstall-StartupTask.ps1",
    "Start-Thoughtbox.ps1",
    "Stop-Thoughtbox.ps1"
)

$allValid = $true

foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Host "Testing $script... " -NoNewline
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script -Raw), [ref]$null)
            Write-Host "OK" -ForegroundColor Green
        } catch {
            Write-Host "FAILED" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
            $allValid = $false
        }
    } else {
        Write-Host "$script... NOT FOUND" -ForegroundColor Yellow
    }
}

Write-Host ""
if ($allValid) {
    Write-Host "All scripts have valid syntax!" -ForegroundColor Green
} else {
    Write-Host "Some scripts have syntax errors. Please review." -ForegroundColor Red
}
