param(
    [Parameter(Mandatory = $false)]
    [string]$VmIp = "localhost",

    [Parameter(Mandatory = $false)]
    [int]$Port = 80
)

$baseUrl = if ($Port -eq 80) { "http://$VmIp" } else { "http://${VmIp}:$Port" }

Write-Host "=== Demo requests to $baseUrl ===" -ForegroundColor Cyan

Write-Host "`nGET /api/health"
Invoke-RestMethod "$baseUrl/api/health" | ConvertTo-Json

Write-Host "`nGET /api/authors"
Invoke-RestMethod "$baseUrl/api/authors" | ConvertTo-Json

Write-Host "`nGET /api/books"
Invoke-RestMethod "$baseUrl/api/books" | ConvertTo-Json

Write-Host "`nPOST /api/authors"
$body = '{"name":"Dostoevsky"}'
Invoke-RestMethod "$baseUrl/api/authors" -Method Post -Body $body -ContentType "application/json" | ConvertTo-Json

Write-Host "`nGET /api/authors (after POST)"
Invoke-RestMethod "$baseUrl/api/authors" | ConvertTo-Json

Write-Host "`n=== All requests OK ===" -ForegroundColor Green
