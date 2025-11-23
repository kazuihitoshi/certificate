#!/usr/bin/env bash
# ca-init.sh
# 使い方: C=JP ST=Yamaguchi OU=IT CN="FUJI-TECHNO Root CA" ./ca-init.sh
# 他に次の指定パラメータも使用可能
# CA_DIR=/opt/ca OPENSSL_CONF=/opt/ca/openssl.cnf

set -euo pipefail
export TOP="`dirname $0`"
if [[ -f $TOP/.env ];then
 . $TOP/.env
fi
export CA_DIR="${CA_DIR:-$TOP/ca}"
export OPENSSL_CONF="${OPENSSL_CONF:-$TOP/ca/openssl.cnf}"
export C="${C:-JP}"
export ST="${ST:-Yamaguchi}"
export O="${O:-ORE Co.,Ltd.}"
export OU="${OU:-IT}"
export CN="${CN:-ORE Root CA}"
export DATABASE="$CA_DIR/index.txt"
export SERIAL="$CA_DIR/serial"
export CA_KEY="$CA_DIR/private/ca.key.pem"
export CA_CERT="$CA_DIR/certs/ca.crt"
export NEW_CRERTS_DIR="$CA_DIR/newcerts"
export DAYS="${DAYS:-3650}"  #約10年
export CERT_DAYS="${CERT_DAYS:-3650}" #約10年
export SIGNER_DAYS="${SIGNER_DAYS:-3650}"       #約10年

mkdir -p "$CA_DIR"/{certs,crl,newcerts,private,csrs,issued,keys,configs}

# OPENSSL_CONF作成
if [[ ! -f "$OPENSSL_CONF" ]];then
cat > "${OPENSSL_CONF}" <<EOF
[ ca ]
default_ca = DEFAULT_CA

[ DEFAULT_CA ]
dir               = $CA_DIR
database          = $DATABASE
new_certs_dir     = $NEW_CRERTS_DIR
certificate       = $CA_CERT
serial            = $SERIAL
# 秘密鍵
private_key       = $CA_KEY
# 有効期限
default_days      = $DAYS
default_md        = sha256
preserve          = no
policy            = policy_loose
x509_extensions   = v3_ca

[ req ]
default_bits      = 4096
default_md        = sha256
distinguished_name= dn
x509_extensions   = v3_ca
prompt            = no
default_days      = ${DAYS}
default_md        = sha256

[ dn ]
# subjのデフォルト値
# Country(国)
C  = ${C}
# State / Province (都道府県)
ST = ${ST}
# Organization（組織名） 会社名または団体名
O  = ${O}
# Organizational Unit（部署）
OU = ${OU}
# Common Name（共通名）通常、証明書の対象名です。CA の場合は「〇〇 Root CA」、サーバー証明書ならFQDN（例：`server01.fuji-techno.com`）
CN = ${CN}

[ policy_loose ]
# 証明書申請時の「Subjectの妥当性チェック」をどれくらい厳しく行うかのルール。
# optional ならほぼなんでも発行できる
countryName            = optional
stateOrProvinceName    = optional
localityName           = optional
organizationName       = optional
organizationalUnitName = optional
commonName             = supplied
emailAddress           = optional

[ v3_ca ]
# 拡張属性
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, keyCertSign, cRLSign

[ codesign_ext ]
keyUsage = critical, digitalSignature
extendedKeyUsage = codeSigning
# 任意：発行者／シリアルやタイムスタンプ署名に関する拡張を後から追加可能
EOF
fi


# index.txt / serial 初期化
[ -f "$DATABASE" ] || touch "$DATABASE"
[ -f "$SERIAL" ] || echo 1000 > "$SERIAL"

# CA 秘密鍵
r=false
if [[ ! -f "$CA_KEY" ]]; then
  echo "=== CA 秘密鍵を新規作成します: $CA_KEY ==="
  echo "パスフレーズは必ず控えておいてください。"
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 \
      | openssl pkcs8 -topk8 -v2 aes-256-cbc -iter 200000 -out "$CA_KEY"
  r=true
fi

# ルート CA 証明書
if [[ ! -f "$CA_CERT" ]]; then
  echo "=== ルート CA 証明書を作成します: $CA_CERT ==="
  openssl req \
    -config "$OPENSSL_CONF" \
    -key "$CA_KEY" \
    -new -x509 -days $DAYS -sha256 \
    -extensions v3_ca \
    -out "$CA_CERT"
  r=true
fi

if [[ "$r" == true ]];then
cat <<EOF
===========================================
 CA 初期化完了
  CA DIR      : $CA_DIR
  CA KEY      : $CA_KEY
  CA CERT     : $CA_CERT
  index.txt   : $DATABASE
  serial      : $SERIAL
===========================================
EOF
fi
 
