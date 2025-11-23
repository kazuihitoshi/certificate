#!/usr/bin/env bash
# codesign-cert.sh
# 使い方:
#   ./codesign-cert.sh            # デフォルト CN=FujiTech Macro Signer
#   SIGNER_CN="My Signer" PFX_OUT=mycodesign.pfx PFX_PASS=Secret ./codesign-cert.sh
set -euo pipefail

TOP="`dirname $0`"
. "$TOP/ca-init.sh"

CODESIGN_EXT="${CODESIGN_EXT:-$TOP/codesign_ext.conf}"

SIGNER_CN="${1:-}"
PFX_PASS="${2:-}"    # 実運用では必ず変更
SIGNER_DAYS="${3:-$SIGNER_DAYS}"

if [[ -z "$SIGNER_CN" || -z "$PFX_PASS" ]];then
   echo "Usage: $0 CN(例: MySigner) PFX_PASS [days]" >&2
   exit 1
fi

CA_KEY="$CA_DIR/private/ca.key.pem"
CA_CERT="$CA_DIR/certs/ca.crt"

mkdir -p "$CA_DIR/configs"

CN_="${SIGNER_CN// /_}"
SIGN_KEY="$CA_DIR/keys/${CN_}.key.pem"
SIGN_CSR="$CA_DIR/csrs/${CN_}.csr.pem"
SIGN_CRT="$CA_DIR/issued/${CN_}.crt"

PFX_OUT="$CA_DIR/issued/${CN_}.pfx"

echo "=== コードサイン用証明書を発行します ==="
echo "  CN          : $SIGNER_CN"
echo "  有効日数    : $SIGNER_DAYS"
echo "  PFX         : $PFX_OUT"

# もし既に同じ CN の証明書がある場合 → 先に revoke しておく
if [[ -f "$SIGN_CRT" ]]; then
  echo "[*] 既存のコードサイン証明書を失効させます: $SIGN_CRT"
  openssl ca \
    -config "$OPENSSL_CONF" \
    -revoke "$SIGN_CRT"
fi

# 鍵生成
if [[ ! -f "$SIGN_KEY" ]]; then
  echo "[*] コードサイン用秘密鍵を生成: $SIGN_KEY"
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$SIGN_KEY"
fi

# CSR 生成
echo "[*] CSR を生成: $SIGN_CSR"
openssl req -new \
  -key "$SIGN_KEY" \
  -out "$SIGN_CSR" \
  -subj "/C=${C}/ST=${ST}/O=${O}/OU=${OU}/CN=${SIGNER_CN}"

# CA で署名（codesign_ext を使用）
echo "[*] CA でコードサイン証明書を署名: $SIGN_CRT"
openssl ca \
  -config "$OPENSSL_CONF" \
  -in "$SIGN_CSR" \
  -out "$SIGN_CRT" \
  -days "$SIGNER_DAYS" \
  -notext -md sha256 \
  -extensions codesign_ext

# PFX 出力
echo "[*] PFX を作成: $PFX_OUT"
openssl pkcs12 -export \
  -inkey "$SIGN_KEY" \
  -in "$SIGN_CRT" \
  -certfile "$CA_CERT" \
  -out "$PFX_OUT" \
  -passout "pass:${PFX_PASS}"

chmod g+r,o+r "$PFX_OUT"

echo "==========================================="
echo " コードサイン証明書 発行完了"
echo "  CN              : $SIGNER_CN"
echo "  KEY             : $SIGN_KEY"
echo "  CERT            : $SIGN_CRT"
echo "  PFX             : $PFX_OUT"
echo "==========================================="
