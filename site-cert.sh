#!/usr/bin/env bash
# site-cert.sh
# 使い方: CN=server01 CERT_DAYS=825 ./site-cert.sh server01.fuji-techno.com [有効日数]
set -euo pipefail

TOP="`dirname $0`"
. "$TOP/ca-init.sh"

CN="${1:-$CN}"
DAYS="${2:-$CERT_DAYS}"   # 約 27 ヶ月

if [[ -z "$CN" ]]; then
  echo "Usage: $0 <CN(例: server01.fuji-techno.com)> [days]" >&2
  exit 1
fi

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
  echo "[*] サイト秘密鍵を生成: $KEY"
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$KEY"
fi

# CSR 生成
echo "[*] CSR(証明書要求) を生成: $CSR"
openssl req -new \
  -key "$KEY" \
  -out "$CSR" \
  -subj "/C=${C}/ST=${ST}/O=${O}/OU=${OU}/CN=${CN}"


# 一時的な拡張設定ファイル
EXT_FILE="$(mktemp)"
trap 'rm -f "$EXT_FILE"' EXIT

cat > "$EXT_FILE" <<'EOF'
[ server_cert ]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth
EOF

# CA で署名（index.txt / serial を更新）
echo "[*] CA でサイト証明書を署名: $CRT"
openssl ca \
  -config "$OPENSSL_CONF" \
  -in "$CSR" \
  -out "$CRT" \
  -days "$DAYS" \
  -notext -md sha256 \
  -extfile "$EXT_FILE" \
  -extensions server_cert 
  
echo "==========================================="
echo " サイト証明書 発行完了"
echo "  CN          : $CN"
echo "  KEY         : $KEY"
echo "  CERT        : $CRT"
echo "==========================================="
