# 証明書生成コンテナ
## コンセプト

以下のコンセプトで証明書発行及び秘密鍵の保持を行うコンテナである。

- 秘密鍵は PKCS#8 形式で AES-256 ＆ PBKDF2 (高反復回数) で暗号化保存

- リポジトリには BEGIN ENCRYPTED PRIVATE KEY の鍵だけをコミット

## 使い方

```bash
docker compose run --rm ca bash
```

### 1 CA秘密鍵 / Root CA作成

次のコマンドにて作成する。実行時にCA秘密鍵のパスワードを入力する。

パスワードは確実に覚えておくこと。CA秘密鍵の使用する際にはパスワード入力が必要となる。

```bash
./ca-init.sh
```
ca/private/ca.key.pem CA秘密鍵

ca/certs/ca.crt Root CA配布用

### 2 Site証明書作成

```bash
./site-cert.sh server01.ore.com [有効日数]
```
./ca/keys/server01.ore.com.key.pem  秘密鍵
./ca/issued/server01.ore.com.crt 証明書

### 3 ファイルサーバ証明書

```bash
./san-cert.sh server01.ore.com [有効日数]
```
  ./ca/keys/nas.key.pem  秘密鍵
  
  ./ca/issued/nas.crt  証明書

### 4 コードサイン

```bash
./codesign-cert.sh ore-code-sign password [有効日数]
```
 ./ca/keys/ore-code-sign.key.pem    秘密鍵
 
 ./ca/issued/ore-code-sign.crt      証明書  PCの信頼された発行元へ登録
 
 ./ca/issued/ore-code-sign.pfx      コードを作成するユーザのみ 個人の証明書欄へインストール時に証明書作成時のパスワード入力必要

