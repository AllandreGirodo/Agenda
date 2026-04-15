param(
    [switch]$Web,
    [switch]$Apk,
    [switch]$Deploy,
    [switch]$Clean,
    [string]$EnvFile = ".env.prod",
    [switch]$Help
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    Write-Host "Uso: .\build_prod.ps1 [opcoes]"
    Write-Host ""
    Write-Host "Opcoes:"
    Write-Host "  -Web              Build somente web"
    Write-Host "  -Apk              Build somente apk"
    Write-Host "  -Deploy           Faz deploy no Firebase Hosting apos build web"
    Write-Host "  -Clean            Executa flutter clean antes do build"
    Write-Host "  -EnvFile PATH     Define arquivo de ambiente (padrao: .env.prod)"
    Write-Host "  -Help             Mostra ajuda"
    Write-Host ""
    Write-Host "Exemplos:"
    Write-Host "  .\build_prod.ps1"
    Write-Host "  .\build_prod.ps1 -Web -Deploy"
    Write-Host "  .\build_prod.ps1 -Apk -Clean"
}

if ($Help) {
    Show-Usage
    exit 0
}

$buildWeb = $true
$buildApk = $true

if ($Web -and -not $Apk) {
    $buildWeb = $true
    $buildApk = $false
}

if ($Apk -and -not $Web) {
    $buildWeb = $false
    $buildApk = $true
}

if (-not (Test-Path -LiteralPath $EnvFile)) {
    throw "Erro: arquivo de ambiente nao encontrado: $EnvFile"
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Erro: flutter nao encontrado no PATH"
}

if ($Deploy -and -not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    throw "Erro: firebase CLI nao encontrado no PATH"
}

function Read-EnvValue {
    param([Parameter(Mandatory = $true)][string]$Key)

    $lines = Get-Content -LiteralPath $EnvFile
    $line = $lines |
        Where-Object { $_ -match "^$([regex]::Escape($Key))=" } |
        Select-Object -Last 1

    if (-not $line) {
        return ""
    }

    $value = $line.Substring($line.IndexOf('=') + 1).Trim()

    if ($value.Length -ge 2) {
        if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
            ($value.StartsWith("'") -and $value.EndsWith("'"))) {
            $value = $value.Substring(1, $value.Length - 2)
        }
    }

    return $value.Trim()
}

function Require-EnvValue {
    param([Parameter(Mandatory = $true)][string]$Key)

    $value = Read-EnvValue -Key $Key
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "Erro: chave obrigatoria ausente em ${EnvFile}: $Key"
    }
}

Require-EnvValue -Key "FIREBASE_PROJECT_ID"
Require-EnvValue -Key "FIREBASE_MESSAGING_SENDER_ID"
Require-EnvValue -Key "FIREBASE_STORAGE_BUCKET"
Require-EnvValue -Key "FIREBASE_WEB_API_KEY"
Require-EnvValue -Key "FIREBASE_WEB_APP_ID"
Require-EnvValue -Key "FIREBASE_ANDROID_API_KEY"
Require-EnvValue -Key "FIREBASE_ANDROID_APP_ID"

$FIREBASE_PROJECT_ID = Read-EnvValue -Key "FIREBASE_PROJECT_ID"
$FIREBASE_MESSAGING_SENDER_ID = Read-EnvValue -Key "FIREBASE_MESSAGING_SENDER_ID"
$FIREBASE_STORAGE_BUCKET = Read-EnvValue -Key "FIREBASE_STORAGE_BUCKET"

$FIREBASE_WEB_API_KEY = Read-EnvValue -Key "FIREBASE_WEB_API_KEY"
$FIREBASE_WEB_APP_ID = Read-EnvValue -Key "FIREBASE_WEB_APP_ID"
$FIREBASE_WEB_AUTH_DOMAIN = Read-EnvValue -Key "FIREBASE_WEB_AUTH_DOMAIN"
$RECAPTCHA_SITE_KEY = Read-EnvValue -Key "RECAPTCHA_SITE_KEY"

$FIREBASE_ANDROID_API_KEY = Read-EnvValue -Key "FIREBASE_ANDROID_API_KEY"
$FIREBASE_ANDROID_APP_ID = Read-EnvValue -Key "FIREBASE_ANDROID_APP_ID"

$commonDefines = @(
    "--dart-define=ENV=prod"
    "--dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID"
    "--dart-define=FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID"
    "--dart-define=FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET"
)

if ($Clean) {
    Write-Host "Executando flutter clean..."
    & flutter clean
    if ($LASTEXITCODE -ne 0) { throw "flutter clean falhou" }
}

Write-Host "Executando flutter pub get..."
& flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get falhou" }

if ($buildWeb) {
    $webDefines = @(
        "--dart-define=FIREBASE_WEB_API_KEY=$FIREBASE_WEB_API_KEY"
        "--dart-define=FIREBASE_WEB_APP_ID=$FIREBASE_WEB_APP_ID"
    )

    if (-not [string]::IsNullOrWhiteSpace($FIREBASE_WEB_AUTH_DOMAIN)) {
        $webDefines += "--dart-define=FIREBASE_WEB_AUTH_DOMAIN=$FIREBASE_WEB_AUTH_DOMAIN"
    }

    if (-not [string]::IsNullOrWhiteSpace($RECAPTCHA_SITE_KEY)) {
        $webDefines += "--dart-define=RECAPTCHA_SITE_KEY=$RECAPTCHA_SITE_KEY"
    }

    Write-Host "Gerando build web de producao..."
    $webArgs = @("build", "web", "--release", "--no-wasm-dry-run") + $commonDefines + $webDefines
    & flutter @webArgs
    if ($LASTEXITCODE -ne 0) { throw "flutter build web falhou" }

    Write-Host "Build web concluido em: build/web"

    if ($Deploy) {
        Write-Host "Publicando no Firebase Hosting..."
        & firebase deploy --only hosting
        if ($LASTEXITCODE -ne 0) { throw "firebase deploy falhou" }
    }
}

if ($buildApk) {
    $androidDefines = @(
        "--dart-define=FIREBASE_ANDROID_API_KEY=$FIREBASE_ANDROID_API_KEY"
        "--dart-define=FIREBASE_ANDROID_APP_ID=$FIREBASE_ANDROID_APP_ID"
    )

    Write-Host "Gerando APK release de producao..."
    $apkArgs = @("build", "apk", "--release") + $commonDefines + $androidDefines
    & flutter @apkArgs
    if ($LASTEXITCODE -ne 0) { throw "flutter build apk falhou" }

    Write-Host "APK concluido em: build/app/outputs/flutter-apk/app-release.apk"
}

Write-Host "Fluxo de producao finalizado com sucesso."
