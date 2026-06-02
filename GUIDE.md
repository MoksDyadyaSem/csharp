# Полный гайд: ручной деплой Exam API на Ubuntu (экзамен Linux)

Этот документ — для **самостоятельного** развёртывания: ты приносишь свой проект на VM, сам ставишь пакеты, собираешь, настраиваешь systemd и Nginx.

**Фокус экзамена — Linux и инфраструктура**, а не C#. Код API — формальность (2 модели, 3 контроллера, без БД).

---

## Содержание

1. [Что нужно сдать на экзамене](#1-что-нужно-сдать-на-экзамене)
2. [Общая картина: кто с кем говорит](#2-общая-картина-кто-с-кем-говорит)
3. [Теория для Java/Kotlin-разработчика](#3-теория-для-javakotlin-разработчика)
4. [Подготовка на Windows (до VM)](#4-подготовка-на-windows-до-vm)
5. [Публикация на GitHub](#5-публикация-на-github)
6. [Ручной деплой на Ubuntu — пошагово](#6-ручной-деплой-на-ubuntu--пошагово)
7. [Проверка с Windows](#7-проверка-с-windows)
8. [История команд для сдачи](#8-история-команд-для-сдачи)
9. [Если что-то сломалось](#9-если-что-то-сломалось)
10. [Что могут спросить устно](#10-что-могут-спросить-устно)
11. [Чеклист перед экзаменом](#11-чеклист-перед-экзаменом)
12. [Шпаргалка команд (одной страницей)](#12-шпаргалка-команд-одной-страницей)

---

## 1. Что нужно сдать на экзамене

| Требование | Что это значит на практике |
|------------|----------------------------|
| Web API на .NET 8 | Проект `ExamApi`, target `net8.0` |
| 2 сущности, 2 контроллера | `Author`, `Book` + контроллеры для них |
| Health Check контроллер | `GET /api/health` → JSON со статусом |
| Без БД | Данные в памяти (`List<>`) |
| Код на GitHub | Публичный репозиторий |
| .NET 8 на VM | `aspnetcore-runtime-8.0` |
| Clone в `/home/{user}/app` | Исходники в домашней папке |
| Release в `/var/www/app` (755) | Собранные dll, права `www-data` |
| systemd | Сервис запускает `dotnet ExamApi.dll` |
| HTTP порт 5000 | Приложение слушает 5000 |
| Nginx :80 → :5000 | Reverse proxy |
| Запросы с Windows | curl / PowerShell на IP VM |
| История команд | `history > file` |

---

## 2. Общая картина: кто с кем говорит

```
  [Windows]                    [Ubuntu VM]
  PowerShell/curl  ──HTTP:80──►  Nginx
                                    │
                                    │ proxy_pass
                                    ▼
                                 dotnet ExamApi.dll  :5000
                                    ▲
                                    │ ExecStart
                                 systemd (exam-api.service)
```

**Пример запроса:**

1. Ты на Windows: `curl http://192.168.1.50/api/authors`
2. Пакет приходит на VM, порт **80** (стандартный HTTP)
3. **Nginx** принимает и пересылает на `127.0.0.1:5000`
4. **dotnet** запускает твой `ExamApi.dll`, контроллер отдаёт JSON

**Две папки — не путай:**

| Путь | Содержимое | Аналог |
|------|------------|--------|
| `/home/{user}/app` | Исходники после `git clone` | `~/projects/myapp` |
| `/var/www/app` | Собранный release (`ExamApi.dll`) | `/opt/myapp/app.jar` |

---

## 3. Теория для Java/Kotlin-разработчика

### 3.1. .NET SDK vs Runtime

| | Java/Kotlin | .NET |
|---|-------------|------|
| Компилятор + инструменты | JDK | **SDK** (`dotnet-sdk-8.0`) |
| Только запуск | JRE | **Runtime** (`aspnetcore-runtime-8.0`) |
| Локальная разработка | JDK | SDK |
| Production-сервер | JRE достаточно | Runtime достаточно |

На **экзамене** на VM нужен минимум **runtime**, чтобы запускать `dotnet ExamApi.dll`.

Если собираешь (`publish`) прямо на VM — нужен ещё **SDK** (или собери на Windows и скопируй готовый `/var/www/app` через `scp`).

### 3.2. dotnet run vs dotnet publish

| Команда | Аналог | Когда |
|---------|--------|-------|
| `dotnet run` | `./gradlew bootRun` | Локальная разработка |
| `dotnet publish -c Release -o /var/www/app` | `./gradlew bootJar` + копирование jar | Деплой на сервер |

**`publish`** собирает папку с:
- `ExamApi.dll` — главный файл (как `app.jar`)
- куча `.dll` — зависимости
- `appsettings.json` — конфиг

Запуск на сервере: `dotnet /var/www/app/ExamApi.dll`

### 3.3. Порт 5000 и `0.0.0.0`

В `Program.cs` проекта:

```csharp
builder.WebHost.UseUrls("http://0.0.0.0:5000");
```

| Адрес | Смысл |
|-------|-------|
| `localhost:5000` | Только с самой машины |
| `0.0.0.0:5000` | Слушать на всех интерфейсах |

Nginx стучится на `127.0.0.1:5000` — приложение **обязано** там отвечать.

**Порт 5000** — внутренний (backend). Снаружи клиенты ходят на **80** через Nginx.

### 3.4. Linux-пользователь www-data

На Ubuntu веб-сервисы часто работают от пользователя **`www-data`** (не root).

Аналог: Tomcat под отдельным пользователем, не под root.

Зачем:
- безопасность (процесс не имеет лишних прав)
- стандарт для nginx/apache окружения

### 3.5. Права chmod и chown

```bash
sudo chown -R www-data:www-data /var/www/app   # владелец = www-data
sudo chmod -R 755 /var/www/app                 # rwxr-xr-x
```

**755** расшифровка:
- `7` (владелец): read + write + execute
- `5` (группа): read + execute
- `5` (остальные): read + execute

Для **папки** execute = «можно зайти внутрь». Без этого `dotnet` не прочитает dll.

### 3.6. systemd — менеджер служб Linux

**systemd** — как «демон-менеджер» в Linux: стартует сервисы при загрузке, перезапускает при падении.

**Unit-файл** — текстовая инструкция. Лежит в `/etc/systemd/system/exam-api.service`.

Три секции:

```ini
[Unit]       # когда и в каком порядке запускать
[Service]    # как именно запускать (команда, пользователь, рестарт)
[Install]    # автозапуск при загрузке системы
```

**Ключевые команды:**

| Команда | Что делает |
|---------|------------|
| `systemctl daemon-reload` | Перечитать конфиги после изменения unit-файла |
| `systemctl enable exam-api` | Автозапуск при reboot |
| `systemctl start exam-api` | Запустить сейчас |
| `systemctl status exam-api` | Жив ли процесс |
| `systemctl restart exam-api` | Перезапуск |
| `journalctl -u exam-api -n 50` | Логи сервиса (как `tail -f` логов приложения) |

### 3.7. Nginx — reverse proxy

**Reverse proxy** — «переводчик» перед приложением:

```
Клиент думает:  http://192.168.1.50/api/health  (порт 80)
На самом деле:  http://127.0.0.1:5000/api/health
```

Зачем на экзамене:
- стандартный HTTP-порт 80 (не нужно писать `:5000` в URL)
- один вход для нескольких приложений (на будущее)
- типичная production-схема

**Структура конфигов Ubuntu:**

```
/etc/nginx/sites-available/exam-api   ← файл конфига (лежит, но может быть выключен)
/etc/nginx/sites-enabled/exam-api     ← симлинк на available (активный сайт)
```

```bash
sudo ln -sf /etc/nginx/sites-available/exam-api /etc/nginx/sites-enabled/
```

**`sites-enabled/default`** — дефолтная страница «Welcome to nginx». Её **убирают**, иначе API не откроется.

**Проверка конфига перед применением:**

```bash
sudo nginx -t          # test — синтаксис OK?
sudo systemctl reload nginx   # применить без полной остановки
```

### 3.8. curl — проверка HTTP из терминала

```bash
curl http://localhost/api/health
```

Аналог Postman, но в консоли. На экзамене — основной способ показать, что API живой.

Флаги:
- `-v` — verbose (заголовки, код ответа)
- `-X POST` — метод POST
- `-H "Content-Type: application/json"` — заголовок
- `-d '{"name":"Test"}'` — тело запроса

### 3.9. SSH

С Windows подключаешься к VM:

```powershell
ssh maxim@192.168.1.50
```

После входа все команды выполняются **на Linux**, не на Windows.

`sudo` — выполнить команду от root (как «Run as administrator»).

### 3.10. Firewall (ufw)

```bash
sudo ufw status
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 22/tcp    # SSH — не заблокируй себя!
```

Если VM в облаке — ещё **Security Group** в веб-панели провайдера.

---

## 4. Подготовка на Windows (до VM)

### 4.1. Проверь, что проект собирается

```powershell
cd d:\linux-project\ExamApi
dotnet build
dotnet run
```

В **другом** терминале:

```powershell
Invoke-RestMethod http://localhost:5000/api/health
Invoke-RestMethod http://localhost:5000/api/authors
Invoke-RestMethod http://localhost:5000/api/books
```

Если здесь не работает — на VM тоже не заработает. Сначала чини локально.

### 4.2. Проверь publish локально (опционально)

```powershell
cd d:\linux-project
dotnet publish ExamApi/ExamApi.csproj -c Release -o .\publish-test
dir .\publish-test\ExamApi.dll
```

Файл `ExamApi.dll` должен появиться.

---

## 5. Публикация на GitHub

Экзамен требует репозиторий на GitHub.

```powershell
cd d:\linux-project
git init
git add .
git commit -m "Exam API: Book/Author REST + deploy configs"
```

На github.com → **New repository** → имя `exam-api` → **без** README (он уже есть локально).

```powershell
git remote add origin https://github.com/YOUR_USER/exam-api.git
git branch -M main
git push -u origin main
```

Запиши URL — он понадобится на VM: `https://github.com/YOUR_USER/exam-api.git`

---

## 6. Ручной деплой на Ubuntu — пошагово

Подставь свои значения:

| Переменная | Пример | Как узнать |
|------------|--------|------------|
| `{user}` | `maxim` | `whoami` на VM |
| `{vm-ip}` | `192.168.1.50` | `ip a` на VM или настройки VirtualBox/VMware |
| `{repo-url}` | `https://github.com/you/exam-api.git` | GitHub |

---

### Шаг 1. Подключись к VM

**На Windows (PowerShell):**

```powershell
ssh {user}@{vm-ip}
```

**Проверка на VM:**

```bash
whoami          # → {user}
pwd             # → /home/{user}
uname -a          # → Ubuntu ...
```

> **Теория:** SSH — зашифрованный удалённый терминал. Все следующие команды (если не указано иное) — **на VM**.

---

### Шаг 2. Установи .NET 8, Nginx, Git

Делается **один раз** на чистой VM.

**Ubuntu 22.04:**

```bash
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y aspnetcore-runtime-8.0 dotnet-sdk-8.0 nginx git
```

| Пакет | Зачем |
|-------|-------|
| `aspnetcore-runtime-8.0` | Запуск `dotnet ExamApi.dll` |
| `dotnet-sdk-8.0` | `dotnet publish` на VM |
| `nginx` | Reverse proxy :80 → :5000 |
| `git` | `git clone` с GitHub |

**Проверка .NET:**

```bash
dotnet --list-runtimes
```

Ожидаешь строку: `Microsoft.AspNetCore.App 8.x.x`

**Проверка Nginx:**

```bash
sudo systemctl status nginx
curl http://localhost
```

Увидишь HTML «Welcome to nginx» — nginx работает (позже заменим на API).

> **Ubuntu 20.04?** Замени в URL `22.04` на `20.04` в ссылке packages-microsoft-prod.deb

---

### Шаг 3. Клонируй репозиторий

Требование экзамена: `/home/{user}/app`

```bash
mkdir -p /home/{user}/app
cd /home/{user}/app
git clone {repo-url} .
ls -la
```

Должны быть папки `ExamApi/`, `deploy/`, файлы `README.md`, `GUIDE.md`.

**Точка в конце `git clone URL .`** — клонировать **в текущую папку**, а не в подпапку.

> **Альтернатива без GitHub:** скопировать проект с Windows через `scp -r d:\linux-project\{user}@{vm-ip}:~/app`

---

### Шаг 4. Собери release в /var/www/app

```bash
sudo mkdir -p /var/www/app
dotnet publish /home/{user}/app/ExamApi/ExamApi.csproj -c Release -o /var/www/app
```

**Что делает каждый флаг:**
- `-c Release` — production-сборка (быстрее, без debug-мусора)
- `-o /var/www/app` — куда положить результат

**Проверь содержимое:**

```bash
ls -la /var/www/app
```

Должен быть `ExamApi.dll`.

**Выставь права (требование экзамена — 755):**

```bash
sudo chown -R www-data:www-data /var/www/app
sudo chmod -R 755 /var/www/app
ls -la /var/www/app
```

---

### Шаг 5. Проверь ручной запуск (рекомендуется)

Перед systemd убедись, что dll вообще стартует.

**Терминал 1:**

```bash
cd /var/www/app
sudo -u www-data /usr/bin/dotnet ExamApi.dll
```

Должно появиться что-то вроде `Now listening on http://0.0.0.0:5000`.

**Терминал 2 (новое SSH-подключение):**

```bash
curl http://127.0.0.1:5000/api/health
curl http://127.0.0.1:5000/api/authors
```

JSON пришёл — отлично. **Ctrl+C** в терминале 1 — останови ручной процесс.

> Если тут ошибка — не переходи к systemd. Смотри текст ошибки: часто «framework not found» = не установлен runtime 8.

---

### Шаг 6. Настрой systemd

**Создай unit-файл:**

```bash
sudo nano /etc/systemd/system/exam-api.service
```

Вставь (можно скопировать из `deploy/exam-api.service` в проекте):

```ini
[Unit]
Description=Exam .NET API
After=network.target

[Service]
WorkingDirectory=/var/www/app
ExecStart=/usr/bin/dotnet /var/www/app/ExamApi.dll
Restart=always
RestartSec=10
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target
```

**Сохранение в nano:** `Ctrl+O` → Enter → `Ctrl+X`

| Строка | Объяснение |
|--------|------------|
| `WorkingDirectory=/var/www/app` | Рабочая папка процесса |
| `ExecStart=/usr/bin/dotnet /var/www/app/ExamApi.dll` | Команда запуска |
| `Restart=always` | Упал — systemd поднимет снова через 10 сек |
| `User=www-data` | Не root |
| `WantedBy=multi-user.target` | Старт при загрузке системы |

**Активируй сервис:**

```bash
sudo systemctl daemon-reload
sudo systemctl enable exam-api
sudo systemctl start exam-api
sudo systemctl status exam-api
```

Ищи строку: **`Active: active (running)`** зелёным.

**Проверка API (ещё без nginx):**

```bash
curl http://127.0.0.1:5000/api/health
curl http://127.0.0.1:5000/api/authors
```

**Если не running:**

```bash
sudo journalctl -u exam-api -n 50 --no-pager
```

Это главный инструмент диагностики — читай последние строки ошибки.

---

### Шаг 7. Настрой Nginx

**Создай конфиг:**

```bash
sudo nano /etc/nginx/sites-available/exam-api
```

Вставь:

```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass         http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

| Директива | Смысл |
|-----------|-------|
| `listen 80` | Nginx слушает HTTP |
| `proxy_pass http://127.0.0.1:5000` | Переслать запрос приложению |
| `proxy_set_header Host $host` | Передать оригинальный Host |

**Включи сайт:**

```bash
sudo ln -sf /etc/nginx/sites-available/exam-api /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
```

**Проверь и примени:**

```bash
sudo nginx -t
sudo systemctl reload nginx
```

`nginx -t` должен сказать: **syntax is ok** и **test is successful**.

**Проверка через nginx (обрати внимание — без :5000):**

```bash
curl http://localhost/api/health
curl http://localhost/api/authors
curl http://localhost/api/books
```

---

### Шаг 8. Firewall (если с Windows не достучаться)

**На VM:**

```bash
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 22/tcp
```

**Проверь, что порт слушается:**

```bash
ss -tlnp | grep -E ':80|:5000'
```

- `:5000` — dotnet (exam-api)
- `:80` — nginx

---

### Шаг 9. Обновление после изменения кода

Когда меняешь код и пушишь в GitHub:

```bash
cd /home/{user}/app
git pull
dotnet publish /home/{user}/app/ExamApi/ExamApi.csproj -c Release -o /var/www/app
sudo chown -R www-data:www-data /var/www/app
sudo chmod -R 755 /var/www/app
sudo systemctl restart exam-api
curl http://localhost/api/health
```

---

## 7. Проверка с Windows

**PowerShell:**

```powershell
$ip = "{vm-ip}"

Invoke-RestMethod "http://$ip/api/health"
Invoke-RestMethod "http://$ip/api/authors"
Invoke-RestMethod "http://$ip/api/books"

$body = '{"name":"Dostoevsky"}'
Invoke-RestMethod "http://$ip/api/authors" -Method Post -Body $body -ContentType "application/json"

Invoke-RestMethod "http://$ip/api/authors"
```

**curl (Windows 10+):**

```powershell
curl.exe http://{vm-ip}/api/health
curl.exe http://{vm-ip}/api/authors
curl.exe -X POST http://{vm-ip}/api/authors -H "Content-Type: application/json" -d "{\"name\":\"Pushkin\"}"
```

**Ожидаемый результат health:**

```json
{"status":"Healthy","timestamp":"2026-05-31T12:00:00.0000000Z"}
```

> URL **без порта** — значит nginx на 80 работает правильно.

---

## 8. История команд для сдачи

**На VM (в конце работы):**

```bash
history > ~/exam-deploy-history.txt
cat ~/exam-deploy-history.txt
```

**На Windows:**

```powershell
Get-History | Format-Table -AutoSize
```

Или сохрани скриншоты успешных `curl` / `Invoke-RestMethod`.

---

## 9. Если что-то сломалось

### Дерево диагностики

```
С Windows не открывается?
├── ping {vm-ip} — VM доступна?
├── curl на VM: localhost/api/health — nginx OK?
│   ├── Нет → nginx / sites-enabled / ufw
│   └── Да → firewall / Security Group / сеть Windows↔VM
└── curl на VM: 127.0.0.1:5000/api/health — app OK?
    ├── Нет → systemctl status + journalctl
    └── Да → проблема только в nginx
```

### Таблица симптомов

| Симптом | Команда | Частая причина |
|---------|---------|----------------|
| `502 Bad Gateway` | `sudo systemctl status exam-api` | Приложение не запущено |
| `502 Bad Gateway` | `sudo journalctl -u exam-api -n 30` | Нет runtime / ошибка dll |
| `Welcome to nginx` | `ls /etc/nginx/sites-enabled/` | Активен `default`, не `exam-api` |
| `Connection refused` :5000 | `ss -tlnp \| grep 5000` | systemd не стартовал app |
| `Permission denied` | `ls -la /var/www/app` | Неверный chown/chmod |
| `dotnet: command not found` | `which dotnet` | Runtime не установлен |
| `framework not found` | `dotnet --list-runtimes` | Нет `Microsoft.AspNetCore.App 8.x` |

### Команды перезапуска

```bash
# После изменения кода:
sudo systemctl restart exam-api

# После изменения nginx:
sudo nginx -t && sudo systemctl reload nginx

# После изменения unit-файла:
sudo systemctl daemon-reload
sudo systemctl restart exam-api
```

---

## 10. Что могут спросить устно

**Зачем nginx, если приложение уже слушает 5000?**
→ Стандартный порт 80, один вход, типичная production-схема. Клиент не знает про внутренний порт 5000.

**Зачем systemd?**
→ Автозапуск при reboot, автоматический restart при падении, единый способ управления сервисами в Linux.

**Почему www-data, а не root?**
→ Безопасность: процесс приложения не должен иметь root-права.

**Чем `/home/user/app` отличается от `/var/www/app`?**
→ `/home/.../app` — исходники для разработки/сборки. `/var/www/app` — готовый release для production.

**Что делает `dotnet publish`?**
→ Собирает приложение и все зависимости в одну папку для деплоя.

**Что такое reverse proxy?**
→ Сервер принимает запросы от клиента и пересылает их backend-приложению, возвращая ответ клиенту.

---

## 11. Чеклист перед экзаменом

**Код (готов заранее):**
- [ ] 2 модели: Author, Book
- [ ] 2 контроллера + HealthController
- [ ] Репозиторий на GitHub
- [ ] `Program.cs` слушает `0.0.0.0:5000`

**Linux (тренируй 2–3 раза руками):**
- [ ] SSH на VM
- [ ] Установка runtime + nginx + git
- [ ] `git clone` в `~/app`
- [ ] `dotnet publish -o /var/www/app`
- [ ] `chown www-data` + `chmod 755`
- [ ] Создание и запуск `exam-api.service`
- [ ] Nginx config + убрать default
- [ ] `curl` с VM (порт 5000 и порт 80)
- [ ] Запросы с Windows по IP
- [ ] `history` сохранена

---

## 12. Шпаргалка команд (одной страницей)

```bash
# === VM: установка (один раз) ===
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb && sudo apt update
sudo apt install -y aspnetcore-runtime-8.0 dotnet-sdk-8.0 nginx git
dotnet --list-runtimes

# === VM: clone + publish ===
mkdir -p ~/app && cd ~/app
git clone {repo-url} .
sudo mkdir -p /var/www/app
dotnet publish ~/app/ExamApi/ExamApi.csproj -c Release -o /var/www/app
sudo chown -R www-data:www-data /var/www/app
sudo chmod -R 755 /var/www/app

# === VM: systemd ===
sudo nano /etc/systemd/system/exam-api.service   # вставить unit-файл
sudo systemctl daemon-reload
sudo systemctl enable exam-api
sudo systemctl start exam-api
sudo systemctl status exam-api
curl http://127.0.0.1:5000/api/health

# === VM: nginx ===
sudo nano /etc/nginx/sites-available/exam-api   # вставить nginx config
sudo ln -sf /etc/nginx/sites-available/exam-api /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
curl http://localhost/api/health

# === VM: firewall + history ===
sudo ufw allow 80/tcp && sudo ufw allow 22/tcp
history > ~/exam-deploy-history.txt
```

```powershell
# === Windows: проверка ===
ssh {user}@{vm-ip}
Invoke-RestMethod http://{vm-ip}/api/health
Invoke-RestMethod http://{vm-ip}/api/authors
```

---

## Файлы в проекте для копирования

Готовые шаблоны (можно копировать вручную или через `cp`):

- `deploy/exam-api.service` → `/etc/systemd/system/exam-api.service`
- `deploy/nginx-exam-api.conf` → `/etc/nginx/sites-available/exam-api`

На экзамене допустимо и `sudo cp ~/app/deploy/exam-api.service /etc/systemd/system/`, и ручной ввод через `nano` — главное понимать содержимое.
