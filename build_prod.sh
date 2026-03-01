#!/bin/bash

# Script de Build para Produção
# Uso: ./build_prod.sh

echo "🚀 Iniciando build de produção (APK)..."

# Verifica se o arquivo de ambiente de produção existe
if [ ! -f ".env.prod" ]; then
    echo "❌ Erro Crítico: Arquivo .env.prod não encontrado!"
    echo "   Certifique-se de criar este arquivo com as chaves de produção antes de gerar o build."
    exit 1
fi

# Limpa builds anteriores para garantir integridade
flutter clean

# Gera o APK release passando a flag de ambiente PROD
flutter build apk --release --dart-define=ENV=prod

echo "✅ Build concluído! O APK está em: build/app/outputs/flutter-apk/app-release.apk"