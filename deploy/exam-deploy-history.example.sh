# Пример истории команд для экзамена (Ubuntu VM)
# На VM после деплоя: history > ~/exam-deploy-history.txt

# Блок B: установка
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y aspnetcore-runtime-6.0 dotnet-sdk-6.0 nginx git
dotnet --list-runtimes

# Блок C: clone
mkdir -p ~/app
cd ~/app
git clone https://github.com/YOUR_USER/exam-api.git .

# Блок D–F: deploy (или ./deploy/deploy.sh $(whoami))
sudo mkdir -p /var/www/app
dotnet publish ~/app/ExamApi/ExamApi.csproj -c Release -o /var/www/app
sudo chown -R www-data:www-data /var/www/app
sudo chmod -R 755 /var/www/app
sudo cp ~/app/deploy/exam-api.service /etc/systemd/system/exam-api.service
sudo systemctl daemon-reload
sudo systemctl enable exam-api
sudo systemctl start exam-api
sudo systemctl status exam-api
curl http://127.0.0.1:5000/api/health
sudo cp ~/app/deploy/nginx-exam-api.conf /etc/nginx/sites-available/exam-api
sudo ln -sf /etc/nginx/sites-available/exam-api /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
curl http://localhost/api/health

history > ~/exam-deploy-history.txt
