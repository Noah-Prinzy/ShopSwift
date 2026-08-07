$BaseUrl = if ($env:BASE_URL) { $env:BASE_URL } else { "http://127.0.0.1:8080" }
$Stamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$Email = "phase1-$Stamp@example.com"
$Username = "phase1-$Stamp"

# Confirm the server is reachable.
Invoke-RestMethod -Method Get -Uri "$BaseUrl/health" | Out-Host

# Create a unique real account. The returned token authenticates later requests.
$AuthBody = @{ username=$Username; email=$Email; password="password123" } | ConvertTo-Json
$Auth = Invoke-RestMethod -Method Post -Uri "$BaseUrl/api/v1/auth/signup" -ContentType "application/json" -Body $AuthBody
$Headers = @{ Authorization = "Bearer $($Auth.token)" }

# Read products and add the known seeded phone to the database-backed cart.
Invoke-RestMethod -Method Get -Uri "$BaseUrl/api/v1/products" | Out-Null
$CartBody = @{ productID="10000000-0000-0000-0000-000000000001"; quantity=1 } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "$BaseUrl/api/v1/cart/items" -Headers $Headers -ContentType "application/json" -Body $CartBody | Out-Host

# Checkout validates the full prototype loop and should empty the cart.
Invoke-RestMethod -Method Post -Uri "$BaseUrl/api/v1/orders/checkout" -Headers $Headers | Out-Host
Write-Host "Phase 1 smoke test passed for $Email"
