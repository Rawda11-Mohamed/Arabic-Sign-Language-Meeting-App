# PowerShell script to add Windows Firewall rule for Flask API
# Run this as Administrator

Write-Host "=" -NoNewline
Write-Host ("=" * 59)
Write-Host "Adding Windows Firewall Rule for Flask API (Port 5000)"
Write-Host "=" -NoNewline
Write-Host ("=" * 59)
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host "Then run this script again."
    Write-Host ""
    pause
    exit 1
}

Write-Host "Adding firewall rule for port 5000..." -ForegroundColor Green

try {
    # Add inbound rule for port 5000
    $rule = New-NetFirewallRule -DisplayName "Flask API Port 5000" `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort 5000 `
        -Action Allow `
        -Profile Domain,Private,Public `
        -Description "Allow Flask API connections on port 5000 for sign language recognition"

    Write-Host "✓ Firewall rule added successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Rule details:"
    Write-Host "  Name: Flask API Port 5000"
    Write-Host "  Port: 5000"
    Write-Host "  Protocol: TCP"
    Write-Host "  Action: Allow"
    Write-Host ""
    Write-Host "You can now test the connection from your phone:" -ForegroundColor Cyan
    Write-Host "  http://192.168.1.14:5000/test" -ForegroundColor Yellow
    Write-Host ""
    
} catch {
    Write-Host "ERROR: Failed to add firewall rule" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Try adding the rule manually:" -ForegroundColor Yellow
    Write-Host "1. Open Windows Defender Firewall"
    Write-Host "2. Advanced settings → Inbound Rules → New Rule"
    Write-Host "3. Port → TCP → 5000 → Allow"
    Write-Host ""
    pause
    exit 1
}

Write-Host "=" -NoNewline
Write-Host ("=" * 59)
pause
