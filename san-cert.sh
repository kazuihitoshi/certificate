#!/usr/bin/env bash
# san-cert.sh
# 使い方:
#   ./san-cert.sh dc1.ore-ad.local
#   ./san-cert.sh dc1.ore-ad.local "dc1,ore.local,dc1.ore-ad.local" 825
set -euo pipefail

TOP="`dirname $0`"
. "$TOP/ca-init.sh"

CN="${1:-}"
SAN_LIST="${2:-}"   # カンマ区切り: "dc1,ore-ad.local,dc1.ore-ad.local"
DAYS="${3:-$CERT_DAYS}"    # 約 27 ヶ月

if [[ -z "$CN" ]]; then
  echo "使い方: $0 <CN> [\"san1,san2,...\"] [days]" >&2
  echo "  例: $0 dc1.ore-ad.local \"dc1,ore-ad.local,dc1.ore-ad.local\" 825" >&2
  exit 1
fi

if [[ -z "$SAN_LIST" ]]; then
  SAN_LIST="$CN"
fi

CA_KEY="$CA_DIR/private/ca.key.pem"
CA_CERT="$CA_DIR/certs/ca.pem"

KEY="$CA_DIR/keys/${CN}.key.pem"
CSR="$CA_DIR/csrs/${CN}.csr.pem"
CRT="$CA_DIR/issued/${CN}.crt"

if [[ -f "$CRT" ]]; then
  echo "[*] 既存の証明書を失効させます: $CRT"
  openssl ca \
    -config "$OPENSSL_CONF" \
    -revoke "$CRT"
fi

# 鍵生成
if [[ ! -f "$KEY" ]]; then
  echo "=== SAN 付きサーバ証明書を発行します ==="
  echo "  CN  : $CN"
  echo "  SAN : $SAN_LIST"
  echo "[*] サイト秘密鍵を生成: $KEY"
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$KEY"
fi

# CSR 生成 (CN のみ / SAN は署名時に付与)
if [[ ! -f "$CSR" ]]; then
  echo "[*] CSR を生成: $CSR"
  openssl req -new \
    -key "$KEY" \
    -out "$CSR" \
    -subj "/C=${C}/ST=${ST}/O=${O}/OU=${OU}/CN=${CN}"
fi

# SAN 用 extfile を作成
EXT_FILE="$(mktemp)"
trap 'rm -f "$EXT_FILE"' EXIT

{
  echo "[ san_cert ]"
  echo "basicConstraints = critical,CA:false"
  echo "keyUsage = critical,digitalSignature,keyEncipherment"
  echo "extendedKeyUsage = serverAuth,clientAuth"
  # subjectAltName 行を生成
  printf "subjectAltName = "
  FIRST=1
  IFS=',' read -ra NAMES <<< "$SAN_LIST"
  for name in "${NAMES[@]}"; do
    name="$(echo "$name" | xargs)"   # trim
    [[ -z "$name" ]] && continue
    if [[ $FIRST -eq 1 ]]; then
      printf "DNS:%s" "$name"
      FIRST=0
    else
      printf ",DNS:%s" "$name"
    fi
  done
  echo
} > "$EXT_FILE"

# CA で署名（SAN 付き）
echo "[*] CA で SAN 付き証明書を署名: $CRT"
openssl ca \
  -config "$OPENSSL_CONF" \
  -in "$CSR" \
  -out "$CRT" \
  -days "$DAYS" \
  -notext -md sha256 \
  -extfile "$EXT_FILE" \
  -extensions san_cert

echo "==========================================="
echo " SAN 証明書 発行完了"
echo "  CN          : $CN"
echo "  SAN         : $SAN_LIST"
echo "  KEY         : $KEY"
echo "  CERT        : $CRT"
echo "==========================================="
