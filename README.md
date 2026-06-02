# Exam API — Book / Author REST

Простой ASP.NET Core 8 Web API для экзамена по Linux.

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

> На Linux VM нужен `aspnetcore-runtime-8.0`.

## Деплой на Ubuntu (экзамен)

**Главное руководство A→Я:** [DEPLOY_FULL.md](DEPLOY_FULL.md)

Теория и разбор: [GUIDE.md](GUIDE.md) · Краткая шпаргалка: [DEPLOY.md](DEPLOY.md)

## Структура проекта

```
ExamApi/           — исходники API
deploy/            — шаблоны systemd + nginx
scripts/           — demo-windows.ps1
GUIDE.md           — теория + разбор команд
DEPLOY_FULL.md     — руководство A→Я (от user до curl)
exam.txt           — команды подряд (шпаргалка)
DEPLOY.md          — краткая шпаргалка
```
