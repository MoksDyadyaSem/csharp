#!/bin/bash
# Деплой Exam API на Ubuntu VM
# Использование: ./deploy/deploy.sh YOUR_LINUX_USERNAME

set -e

USER_NAME="${1:-$(whoami)}"
APP_SRC="/home/${USER_NAME}/app"
DEPLOY_DIR="/var/www/app"

echo "=== Publish to ${DEPLOY_DIR} ==="
sudo mkdir -p "${DEPLOY_DIR}"
dotnet publish "${APP_SRC}/ExamApi/ExamApi.csproj" -c Release -o "${DEPLOY_DIR}"
sudo chown -R www-data:www-data "${DEPLOY_DIR}"
sudo chmod -R 755 "${DEPLOY_DIR}"

echo "=== Install systemd unit ==="
sudo cp "${APP_SRC}/deploy/exam-api.service" /etc/systemd/system/exam-api.service
sudo systemctl daemon-reload
sudo systemctl enable exam-api
sudo systemctl restart exam-api

echo "=== Install nginx config ==="
sudo cp "${APP_SRC}/deploy/nginx-exam-api.conf" /etc/nginx/sites-available/exam-api
sudo ln -sf /etc/nginx/sites-available/exam-api /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

echo "=== Health check ==="
curl -s http://127.0.0.1:5000/api/health
echo ""
curl -s http://localhost/api/health
echo ""
echo "Done. Test from Windows: curl http://VM_IP/api/health"
