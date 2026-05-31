# Пример истории команд для экзамена (Windows PowerShell)
# После деплоя на VM замени localhost на IP виртуалки

# Подключение к VM
# ssh maxim@192.168.1.50

# Демо-запросы с Windows
$ip = "192.168.1.50"   # <-- подставь IP VM

Invoke-RestMethod "http://$ip/api/health"
Invoke-RestMethod "http://$ip/api/authors"
Invoke-RestMethod "http://$ip/api/books"

$body = '{"name":"Dostoevsky"}'
Invoke-RestMethod "http://$ip/api/authors" -Method Post -Body $body -ContentType "application/json"

Invoke-RestMethod "http://$ip/api/authors"

# Или одним скриптом:
# .\scripts\demo-windows.ps1 -VmIp 192.168.1.50
