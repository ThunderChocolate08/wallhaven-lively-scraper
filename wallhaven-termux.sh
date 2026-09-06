#!/data/data/com.termux/files/usr/bin/bash
# Wallhaven Toplist -> Termux (Android open source)
# Requiere: pkg install termux-api jq curl
# Uso: bash wallhaven-termux.sh [page]
set -e
PAGE=${1:-$((RANDOM%10+1))}
DIR="$HOME/storage/pictures/Wallhaven/Toplist"
mkdir -p "$DIR"
API="https://wallhaven.cc/api/v1/search?categories=111&purity=100&sorting=toplist&topRange=1M&page=$PAGE"
echo "API $API"
JSON=$(curl -s "$API")
URL=$(echo "$JSON" | jq -r '.data[0].path')
ID=$(echo "$JSON" | jq -r '.data[0].id')
FILE="$DIR/toplist-p${PAGE}-${ID}.jpg"
echo "Descargando $ID -> $FILE"
curl -L -o "$FILE" "$URL"
termux-wallpaper -f "$FILE"
echo "Wallpaper aplicado $ID"
