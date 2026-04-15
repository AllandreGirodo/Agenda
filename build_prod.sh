#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

ENV_FILE=".env.prod"
BUILD_WEB=true
BUILD_APK=true
DO_DEPLOY=false
DO_CLEAN=false

print_usage() {
    cat <<'EOF'
Uso: ./build_prod.sh [opcoes]

Opcoes:
    --web            Build somente web
    --apk            Build somente apk
    --deploy         Faz deploy no Firebase Hosting apos build web
    --clean          Executa flutter clean antes do build
    --env-file PATH  Define arquivo de ambiente (padrao: .env.prod)
    -h, --help       Mostra ajuda

Exemplos:
    ./build_prod.sh
    ./build_prod.sh --web --deploy
    ./build_prod.sh --apk --clean
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --web)
            BUILD_WEB=true
            BUILD_APK=false
            ;;
        --apk)
            BUILD_APK=true
            BUILD_WEB=false
            ;;
        --deploy)
            DO_DEPLOY=true
            ;;
        --clean)
            DO_CLEAN=true
            ;;
        --env-file)
            shift
            ENV_FILE="${1:-}"
            if [[ -z "$ENV_FILE" ]]; then
                echo "Erro: informe o caminho apos --env-file"
                exit 1
            fi
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Erro: opcao desconhecida: $1"
            print_usage
            exit 1
            ;;
    esac
    shift
done

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Erro: arquivo de ambiente nao encontrado: $ENV_FILE"
    exit 1
fi

command -v flutter >/dev/null 2>&1 || {
    echo "Erro: flutter nao encontrado no PATH"
    exit 1
}

if [[ "$DO_DEPLOY" == true ]]; then
    command -v firebase >/dev/null 2>&1 || {
        echo "Erro: firebase CLI nao encontrado no PATH"
        exit 1
    }
fi

read_env() {
    local key="$1"
    local line
    line="$(grep -E "^${key}=" "$ENV_FILE" | tail -n 1 || true)"
    line="${line%$'\r'}"
    if [[ -z "$line" ]]; then
        echo ""
        return 0
    fi

    local value="${line#*=}"
    value="${value%$'\r'}"
    value="${value%\"}"
    value="${value#\"}"
    value="${value%\'}"
    value="${value#\'}"
    echo "$value"
}

require_env() {
    local key="$1"
    local value
    value="$(read_env "$key")"
    if [[ -z "$value" ]]; then
        echo "Erro: chave obrigatoria ausente em $ENV_FILE: $key"
        exit 1
    fi
}

require_env "FIREBASE_PROJECT_ID"
require_env "FIREBASE_MESSAGING_SENDER_ID"
require_env "FIREBASE_STORAGE_BUCKET"
require_env "FIREBASE_WEB_API_KEY"
require_env "FIREBASE_WEB_APP_ID"
require_env "FIREBASE_ANDROID_API_KEY"
require_env "FIREBASE_ANDROID_APP_ID"

FIREBASE_PROJECT_ID="$(read_env FIREBASE_PROJECT_ID)"
FIREBASE_MESSAGING_SENDER_ID="$(read_env FIREBASE_MESSAGING_SENDER_ID)"
FIREBASE_STORAGE_BUCKET="$(read_env FIREBASE_STORAGE_BUCKET)"

FIREBASE_WEB_API_KEY="$(read_env FIREBASE_WEB_API_KEY)"
FIREBASE_WEB_APP_ID="$(read_env FIREBASE_WEB_APP_ID)"
FIREBASE_WEB_AUTH_DOMAIN="$(read_env FIREBASE_WEB_AUTH_DOMAIN)"
RECAPTCHA_SITE_KEY="$(read_env RECAPTCHA_SITE_KEY)"

FIREBASE_ANDROID_API_KEY="$(read_env FIREBASE_ANDROID_API_KEY)"
FIREBASE_ANDROID_APP_ID="$(read_env FIREBASE_ANDROID_APP_ID)"

COMMON_DEFINES=(
    "--dart-define=ENV=prod"
    "--dart-define=FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}"
    "--dart-define=FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID}"
    "--dart-define=FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET}"
)

if [[ "$DO_CLEAN" == true ]]; then
    echo "Executando flutter clean..."
    flutter clean
fi

echo "Executando flutter pub get..."
flutter pub get

if [[ "$BUILD_WEB" == true ]]; then
    WEB_DEFINES=(
        "--dart-define=FIREBASE_WEB_API_KEY=${FIREBASE_WEB_API_KEY}"
        "--dart-define=FIREBASE_WEB_APP_ID=${FIREBASE_WEB_APP_ID}"
    )

    if [[ -n "$FIREBASE_WEB_AUTH_DOMAIN" ]]; then
        WEB_DEFINES+=("--dart-define=FIREBASE_WEB_AUTH_DOMAIN=${FIREBASE_WEB_AUTH_DOMAIN}")
    fi

    if [[ -n "$RECAPTCHA_SITE_KEY" ]]; then
        WEB_DEFINES+=("--dart-define=RECAPTCHA_SITE_KEY=${RECAPTCHA_SITE_KEY}")
    fi

    echo "Gerando build web de producao..."
    flutter build web --release --no-wasm-dry-run "${COMMON_DEFINES[@]}" "${WEB_DEFINES[@]}"
    echo "Build web concluido em: build/web"

    if [[ "$DO_DEPLOY" == true ]]; then
        echo "Publicando no Firebase Hosting..."
        firebase deploy --only hosting
    fi
fi

if [[ "$BUILD_APK" == true ]]; then
    ANDROID_DEFINES=(
        "--dart-define=FIREBASE_ANDROID_API_KEY=${FIREBASE_ANDROID_API_KEY}"
        "--dart-define=FIREBASE_ANDROID_APP_ID=${FIREBASE_ANDROID_APP_ID}"
    )

    echo "Gerando APK release de producao..."
    flutter build apk --release "${COMMON_DEFINES[@]}" "${ANDROID_DEFINES[@]}"
    echo "APK concluido em: build/app/outputs/flutter-apk/app-release.apk"
fi

echo "Fluxo de producao finalizado com sucesso."