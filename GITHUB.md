# Публикация на GitHub

Репозиторий уже инициализирован и закоммичен локально.

## Шаги

1. Создай **новый публичный** репозиторий на https://github.com/new  
   Имя, например: `exam-api`  
   **Не** добавляй README/license — они уже есть локально.

2. Привяжи remote и запушь:

```powershell
cd d:\linux-project
git remote add origin https://github.com/YOUR_USER/exam-api.git
git branch -M main
git push -u origin main
```

3. На Ubuntu VM клонируй:

```bash
mkdir -p ~/app
cd ~/app
git clone https://github.com/YOUR_USER/exam-api.git .
./deploy/deploy.sh $(whoami)
```

4. Обнови `{repo-url}` в [DEPLOY.md](DEPLOY.md) на свой URL.
