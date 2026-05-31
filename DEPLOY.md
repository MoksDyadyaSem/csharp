# Шпаргалка деплоя (экзамен Linux)

Подставь свои значения перед выполнением:

| Переменная | Пример | Где взять |
|------------|--------|-----------|
| `{user}` | `maxim` | `whoami` на VM |
| `{vm-ip}` | `192.168.1.50` | IP виртуалки |
| `{repo-url}` | `https://github.com/you/exam-api.git` | GitHub |

---

## Блок A: Подключение к VM (с Windows)

```powershell
ssh {user}@{vm-ip}
```

На VM проверь:

```bash
whoami
pwd
uname -a
```

---

## Блок B: Установка .NET 6 + Nginx + Git (один раз)

Ubuntu 22.04:

```bash
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y aspnetcore-runtime-6.0 dotnet-sdk-6.0 nginx git
dotnet --list-runtimes
```

Должна быть строка `Microsoft.AspNetCore.App 6.x`.

Проверка nginx:

```bash
sudo systemctl status nginx
curl http://localhost
```

---

## Блок C: Клонирование репозитория

```bash
mkdir -p /home/{user}/app
cd /home/{user}/app
git clone {repo-url} .
ls -la
```

---

## Блок D: Сборка в /var/www/app

```bash
sudo mkdir -p /var/www/app
dotnet publish /home/{user}/app/ExamApi/ExamApi.csproj -c Release -o /var/www/app
sudo chown -R www-data:www-data /var/www/app
sudo chmod -R 755 /var/www/app
ls -la /var/www/app
```

Проверка ручного запуска (опционально):

```bash
cd /var/www/app
sudo -u www-data /usr/bin/dotnet ExamApi.dll
# В другом SSH-окне:
curl http://127.0.0.1:5000/api/health
# Ctrl+C — остановить ручной запуск
```

---

## Блок E: systemd

```bash
sudo cp /home/{user}/app/deploy/exam-api.service /etc/systemd/system/exam-api.service
sudo systemctl daemon-reload
sudo systemctl enable exam-api
sudo systemctl start exam-api
sudo systemctl status exam-api
curl http://127.0.0.1:5000/api/health
curl http://127.0.0.1:5000/api/authors
```

Если не `active (running)`:

```bash
sudo journalctl -u exam-api -n 50 --no-pager
```

---

## Блок F: Nginx reverse proxy

```bash
sudo cp /home/{user}/app/deploy/nginx-exam-api.conf /etc/nginx/sites-available/exam-api
sudo ln -sf /etc/nginx/sites-available/exam-api /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
curl http://localhost/api/health
curl http://localhost/api/authors
```

---

## Блок G: Firewall (если с Windows не достучаться)

```bash
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 22/tcp
```

В облаке также открой порт 80 в Security Group.

---

## Блок H: Демо с Windows

```powershell
$ip = "{vm-ip}"
Invoke-RestMethod "http://$ip/api/health"
Invoke-RestMethod "http://$ip/api/authors"
Invoke-RestMethod "http://$ip/api/books"
$body = '{"name":"Dostoevsky"}'
Invoke-RestMethod "http://$ip/api/authors" -Method Post -Body $body -ContentType "application/json"
```

Или запусти скрипт:

```powershell
.\scripts\demo-windows.ps1 -VmIp "{vm-ip}"
```

---

## Блок I: История команд

На VM:

```bash
history > ~/exam-deploy-history.txt
cat ~/exam-deploy-history.txt
```

---

## Быстрый деплой одним скриптом

После `git clone` на VM:

```bash
cd /home/{user}/app
chmod +x deploy/deploy.sh
./deploy/deploy.sh {user}
```

---

## Если что-то сломалось

| Симптом | Команда | Причина |
|---------|---------|---------|
| 502 Bad Gateway | `sudo systemctl status exam-api` | приложение не запущено |
| 502 Bad Gateway | `sudo journalctl -u exam-api -n 30` | ошибка dll / нет runtime |
| Welcome to nginx | `ls /etc/nginx/sites-enabled/` | активен default |
| Connection refused | `ss -tlnp \| grep 5000` | приложение не слушает 5000 |

Перезапуск после изменений:

```bash
sudo systemctl restart exam-api
sudo nginx -t && sudo systemctl reload nginx
```
