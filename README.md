# Exam API — Book / Author REST

Простой ASP.NET Core 6 Web API для экзамена по Linux.

## Требования экзамена

- 2 модели: `Author`, `Book`
- 2 контроллера: `AuthorsController`, `BooksController`
- 1 Health Check: `HealthController`
- Без БД, данные в памяти
- Деплой: GitHub → Ubuntu VM → systemd → Nginx

## API endpoints

| Метод | URL | Описание |
|-------|-----|----------|
| GET | `/api/health` | Проверка сервиса |
| GET | `/api/authors` | Список авторов |
| GET | `/api/authors/{id}` | Автор по id |
| POST | `/api/authors` | Создать автора `{"name":"..."}` |
| GET | `/api/books` | Список книг (`?authorId=1` опционально) |
| GET | `/api/books/{id}` | Книга по id |
| POST | `/api/books` | Создать книгу `{"title":"...","authorId":1}` |

## Локальный запуск (Windows)

```powershell
cd ExamApi
dotnet run
```

В другом терминале:

```powershell
Invoke-RestMethod http://localhost:5000/api/health
.\scripts\demo-windows.ps1 -VmIp localhost -Port 5000
```

> На Windows без ASP.NET Core 6 runtime в `ExamApi.csproj` включён `RollForward=Major` — приложение запустится на .NET 8. На Linux VM нужен `aspnetcore-runtime-6.0`.

## Деплой на Ubuntu

Пошаговая инструкция: [DEPLOY.md](DEPLOY.md)

Кратко:

```bash
git clone {repo-url} ~/app
cd ~/app
./deploy/deploy.sh $(whoami)
```

## Структура проекта

```
ExamApi/           — исходники API
deploy/            — systemd + nginx + deploy.sh
scripts/           — demo-windows.ps1
DEPLOY.md          — шпаргалка для экзамена
```
