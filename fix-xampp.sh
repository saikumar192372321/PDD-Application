#!/bin/bash
# ============================================================
# VSN Home - XAMPP Rectification & Reset Script
# Run this script with sudo to resolve XAMPP service conflicts
# ============================================================

echo "🔍 VSN HOME - XAMPP SERVICE RECTIFICATION"
echo "=========================================="
echo "This script terminates orphaned processes, clears stale PID/socket files,"
echo "and starts XAMPP services cleanly so they sync with the GUI manager."
echo ""

# Requesting sudo privileges if not already run as root
if [ "$EUID" -ne 0 ]; then
  echo "⚠️ This script requires administrator privileges to reset system services."
  echo "Please run it with sudo:"
  echo "  sudo bash fix-xampp.sh"
  exit 1
fi

echo "Step 1: Stopping conflicting/orphaned processes..."
killall -9 httpd mysqld 2>/dev/null
sleep 2

echo "Step 2: Cleaning up stale lock, socket, and PID files..."
rm -f /Applications/XAMPP/xamppfiles/logs/httpd.pid
rm -f /Applications/XAMPP/xamppfiles/var/mysql/*.pid
rm -f /Applications/XAMPP/xamppfiles/var/mysql/mysql.sock
rm -f /Applications/XAMPP/xamppfiles/temp/mysql/mysql.sock 2>/dev/null

echo "Step 3: Correcting ownership on MySQL directory..."
chown -R _mysql /Applications/XAMPP/xamppfiles/var/mysql 2>/dev/null
chmod -R 775 /Applications/XAMPP/xamppfiles/var/mysql 2>/dev/null

echo "Step 4: Starting XAMPP services cleanly..."
/Applications/XAMPP/xamppfiles/ctlscript.sh start

echo ""
echo "Step 5: Verifying current service status..."
/Applications/XAMPP/xamppfiles/ctlscript.sh status

echo ""
echo "=========================================="
echo "✅ XAMPP services have been successfully reset and restarted!"
echo "You can now open the XAMPP Manager GUI and it should show all services as running."
echo "=========================================="
