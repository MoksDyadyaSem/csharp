# Руководство A→Я: от пользователя Linux до curl через Nginx

Пошаговая инструкция для экзамена. Подставь свои значения:

| Переменная | Пример |
|------------|--------|
| `{user}` | `exam` |
| `{password}` | твой пароль |
| `{vm-ip}` | `217.60.63.32` |
| `{repo-url}` | `https://github.com/you/exam-api.git` |

**Референсы в проекте (не писать конфиги с нуля):**

| Файл | Куда копировать |
|------|-----------------|
| `deploy/exam-api.service` | `/etc/systemd/system/exam-api.service` |
| `deploy/nginx-exam-api.conf` | `/etc/nginx/sites-available/exam-api` |
| `/etc/nginx/sites-available/default` | образец синтаксиса nginx |

---

## Карта деплоя

```
[1] пользователь exam + SSH
[2] git, nginx, dotnet
[3] git clone → ~/app
[4] dotnet publish → /var/www/app
[5] systemd → :5000
[6] nginx → :80 → :5000
[7] curl с Windows
```

---

## Часть 0. Подключение к VM

### С Windows (если пользователь уже есть)

```powershell
ssh {user}@{vm-ip}
```

### Если пользователя ещё нет — создать (от root)

Зайди на VM как **root** (консоль провайдера или `ssh root@...`):

```bash
adduser exam
```

- введи пароль (два раза)
- Full Name и остальное — Enter (можно пропустить)

```bash
usermod -aG sudo exam
```

**Зачем `sudo`:** пользователь сможет выполнять админ-команды (`apt install`, `systemctl`).

Проверка:

```bash
id exam
```

Дальше работай **под exam**:

```bash
su - exam
whoami
```

Должно быть: `exam`.

---

## Часть 1. Установка пакетов

### 1.1 Репозиторий Microsoft (.NET)

Ubuntu **24.04**:

```bash
wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
```

Ubuntu **22.04** — замени `24.04` на `22.04` в URL.

| Команда | Зачем |
|---------|--------|
| `wget ... -O file` | скачать .deb |
| `dpkg -i` | добавить источник пакетов Microsoft |
| `apt update` | обновить список пакетов |

### 1.2 Установка git, nginx, .NET

**Только запуск API** (publish делаешь на другой машине):

```bash
sudo apt install -y git nginx aspnetcore-runtime-8.0
```

**Запуск + сборка на VM** (обычно на экзамене):

```bash
sudo apt install -y git nginx dotnet-sdk-8.0
```

`dotnet-sdk-8.0` включает runtime и `dotnet publish`.

### 1.3 Проверка

```bash
git --version
nginx -v
dotnet --list-runtimes
dotnet --list-sdks
```

Ожидаешь строку: `Microsoft.AspNetCore.App 8.x`.

### 1.4 Как найти имя пакета самому

```bash
apt search aspnetcore-runtime
apt search dotnet-sdk
apt-cache policy dotnet-sdk-8.0
```

Версия (`8.0`) = `TargetFramework` в `ExamApi.csproj` (`net8.0` → `...-8.0`).

---

## Часть 2. Клонирование репозитория

Требование экзамена: `/home/{user}/app`

```bash
mkdir -p ~/app
cd ~/app
git clone {repo-url} .
ls -la
```

| Команда | Зачем |
|---------|--------|
| `mkdir -p ~/app` | создать папку |
| `git clone URL .` | точка = клонировать **в текущую** папку, без лишней подпапки |

Проверка:

```bash
ls ~/app/ExamApi/ExamApi.csproj
ls ~/app/deploy/
```

---

## Часть 3. Сборка release в /var/www/app

```bash
sudo mkdir -p /var/www/app
sudo dotnet publish ~/app/ExamApi/ExamApi.csproj -c Release -o /var/www/app
sudo chown -R www-data:www-data /var/www/app
sudo chmod -R 755 /var/www/app
ls -la /var/www/app
```

| Команда / флаг | Зачем |
|--------------|--------|
| `sudo mkdir -p` | создать папку деплоя (нужны права root) |
| `dotnet publish` | собрать release (dll + зависимости) |
| `-c Release` | production-сборка |
| `-o /var/www/app` | куда положить результат |
| `chown www-data` | владелец = пользователь веб-сервисов |
| `chmod 755` | требование экзамена |

Должен быть файл **`ExamApi.dll`**.

### 3.1 Ручная проверка (до systemd)

**Терминал 1:**

```bash
cd /var/www/app
sudo -u www-data env HOME=/var/www/app DOTNET_CLI_HOME=/var/www/app /usr/bin/dotnet ExamApi.dll
```

**Терминал 2:**

```bash
curl http://127.0.0.1:5000/api/health
```

JSON → **Ctrl+C** в терминале 1.

---

## Часть 4. systemd (демон)

### 4.1 Референс — скопировать из репозитория

```bash
sudo cp ~/app/deploy/exam-api.service /etc/systemd/system/exam-api.service
```

Допиши (если нет в файле — нужно для `www-data`):

```bash
sudo nano /etc/systemd/system/exam-api.service
```

После `User=www-data` добавь:

```ini
Environment=HOME=/var/www/app
Environment=DOTNET_CLI_HOME=/var/www/app
```

### 4.2 Минимальный рабочий unit (эталон)

```ini
[Unit]
Description=Exam .NET API
After=network.target

[Service]
WorkingDirectory=/var/www/app
ExecStart=/usr/bin/dotnet /var/www/app/ExamApi.dll
User=www-data
Environment=HOME=/var/www/app
Environment=DOTNET_CLI_HOME=/var/www/app
Environment=ASPNETCORE_ENVIRONMENT=Production
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Имя файла:** `exam-api.service` (не `exap-api`).

### 4.3 Опечатки — проверь перед start

| ❌ | ✅ |
|----|-----|
| `WorkingDirector` | `WorkingDirectory` |
| `ExexStart` | `ExecStart` |
| `ExampleApi.dll` | `ExamApi.dll` |
| `Enviroment` | `Environment` |
| `WatnedBy` | `WantedBy` |

### 4.4 Запуск службы

```bash
sudo systemctl daemon-reload
sudo systemctl enable exam-api
sudo systemctl start exam-api
sudo systemctl status exam-api
```

Подожди 5–10 сек (или смотри в логах `Now listening on :5000`):

```bash
sudo journalctl -u exam-api -n 20 --no-pager
curl http://127.0.0.1:5000/api/health
curl http://127.0.0.1:5000/api/authors
```

| Команда | Зачем |
|---------|--------|
| `daemon-reload` | перечитать unit после правок |
| `enable` | автозапуск при reboot |
| `start` | запустить сейчас |
| `status` | жив ли процесс |

**Референс синтаксиса systemd:** `systemctl cat nginx`

---

## Часть 5. Nginx (reverse proxy)

### 5.1 Референсы

```bash
cat /etc/nginx/sites-available/default
cat ~/app/deploy/nginx-exam-api.conf
```

- **default** — образец `server { listen; location }`
- **deploy/nginx-exam-api.conf** — готовый proxy на API

### 5.2 Установка конфига exam-api

```bash
sudo cp ~/app/deploy/nginx-exam-api.conf /etc/nginx/sites-available/exam-api
```

Проверь порт (**5000**, не 5050):

```bash
grep proxy_pass /etc/nginx/sites-available/exam-api
```

### 5.3 Минимальный конфиг (достаточно для экзамена)

```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
    }
}
```

### 5.4 Включить сайт

```bash
sudo ln -sf /etc/nginx/sites-available/exam-api /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

| Команда | Зачем |
|---------|--------|
| `ln -sf ... sites-enabled/` | **включить** сайт (симлинк) |
| `rm default` из enabled | убрать Welcome to nginx с :80 |
| `nginx -t` | проверить синтаксис |
| `reload nginx` | применить конфиг |

**Не удаляй** папку `sites-enabled/` — только файлы внутри.

### 5.5 Проверка через nginx

```bash
curl http://localhost/api/health
curl http://localhost/api/authors
```

Без `:5000` — идёшь через nginx на порт 80.

---

## Часть 6. Firewall (если с Windows не открывается)

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 5000/tcp
sudo ufw status
```

В панели VPS (Security Group) — inbound **22** и **80**.

---

## Часть 7. Проверка с Windows

**Не используй `127.0.0.1`** — это твой ПК, не VPS.

```powershell
curl.exe http://{vm-ip}:5000/api/health
curl.exe http://{vm-ip}:5000/api/authors

curl.exe http://{vm-ip}/api/health
curl.exe http://{vm-ip}/api/authors
curl.exe http://{vm-ip}/api/books
```

POST пример:

```powershell
curl.exe -X POST http://{vm-ip}/api/authors -H "Content-Type: application/json" -d "{\"name\":\"Pushkin\"}"
```

---

## Часть 8. История команд (сдача)

```bash
history > ~/exam-deploy-history.txt
cat ~/exam-deploy-history.txt
```

---

## Полная последовательность одним списком

```bash
# === 0. Пакеты ===
wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y git nginx dotnet-sdk-8.0

# === 1. Clone ===
mkdir -p ~/app && cd ~/app
git clone {repo-url} .

# === 2. Publish ===
sudo mkdir -p /var/www/app
sudo dotnet publish ~/app/ExamApi/ExamApi.csproj -c Release -o /var/www/app
sudo chown -R www-data:www-data /var/www/app
sudo chmod -R 755 /var/www/app

# === 3. systemd ===
sudo cp ~/app/deploy/exam-api.service /etc/systemd/system/exam-api.service
sudo nano /etc/systemd/system/exam-api.service   # HOME + DOTNET_CLI_HOME
sudo systemctl daemon-reload
sudo systemctl enable exam-api
sudo systemctl start exam-api
curl http://127.0.0.1:5000/api/health

# === 4. nginx ===
sudo cp ~/app/deploy/nginx-exam-api.conf /etc/nginx/sites-available/exam-api
sudo ln -sf /etc/nginx/sites-available/exam-api /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
curl http://localhost/api/health

# === 5. history ===
history > ~/exam-deploy-history.txt
```

---

## Если что-то сломалось

| Симптом | Команда | Частая причина |
|---------|---------|----------------|
| `502 Bad Gateway` | `sudo systemctl status exam-api` | app не running |
| `502` | `grep proxy_pass .../exam-api` | порт 5050 вместо 5000 |
| `Connection refused` :5000 | `ss -tlnp \| grep 5000` | app не слушает |
| `Unit could not be found` | `ls /etc/systemd/system/exam-api.service` | опечатка exap-api |
| `bad-setting` | `sudo journalctl -u exam-api` | ExexStart, Enviroment |
| curl с Windows не работает | `curl http://127.0.0.1:5000/...` на VPS | firewall / не тот IP |
| `Now listening` через 20+ сек | подожди после `start` | медленный старт |

---

## Чеклист «готово»

- [ ] пользователь `exam`, SSH работает
- [ ] `git`, `nginx`, `dotnet` установлены
- [ ] `~/app` — clone
- [ ] `/var/www/app/ExamApi.dll` — publish, www-data, 755
- [ ] `systemctl status exam-api` → **active (running)**
- [ ] `curl :5000/api/health` на VPS
- [ ] `curl :80/api/health` на VPS (nginx)
- [ ] `curl.exe http://{vm-ip}/api/health` с Windows
- [ ] `history` сохранена

---

## Дополнительно

- Теория и разбор команд: [GUIDE.md](GUIDE.md)
- Краткая шпаргалка: [DEPLOY.md](DEPLOY.md)
