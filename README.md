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
- 作成されるファイル
 
|作成されるファイル | サーバ用途  | PC証明書インストール | 備考 |
|-----------------|-------------|--------------|------|
|ca/private/ca.key.pem CA秘密鍵| 特になし  |    |       |
|ca/certs/ca.crt Root CA配布用 | 特になし  |PCの信頼されたルート証明機関へインストール| |

### 2 Site証明書作成

```bash
./site-cert.sh server01.ore.com [有効日数]
```

- 生成されるファイル

|作成されるファイル | サーバ用途  | PC証明書インストール | 備考 |
|-----------------|-------------|--------------|------|
|./ca/keys/server01.ore.com.key.pem  秘密鍵|/etc/apache2/ssl/  <br> sites-enabled/default-ssl.conf<br>SSLCertificateKeyFile         /etc/apache2/ssl/server01.ore.com.key.pem | なし |  |
|./ca/issued/server01.ore.com.crt 証明書|/etc/apache2/ssl/  <br> sites-enabled/default-ssl.conf<br>SSLCertificateFile            /etc/apache2/ssl/server01.ore.com.crt | なし |  |

### 3 ファイルサーバ証明書

```bash
./san-cert.sh server01.ore.com [有効日数]
```
- 生成されるファイル

|作成されるファイル | サーバ用途  | PC証明書インストール | 備考 |
|-----------------|-------------|--------------|------|
|./ca/keys/nas.key.pem 秘密鍵|/usr/local/samba/private/tls/private.key<br>tls keyfile 設定で指定| 特になし | |
|./ca/issued/nas.crt 証明書|/usr/local/samba/private/tls/cert.pem<br>tls certfile 設定で指定| 特になし | |
|./ca/certs/ca.crt RootCA| /var/lib/samba/private/tls/ca.pem | PCの信頼されたルート証明機関へインストール | |

### 4 コードサイン

```bash
./codesign-cert.sh ore-code-sign password [有効日数]
```
 ./ca/keys/ore-code-sign.key.pem    秘密鍵
 
 ./ca/issued/ore-code-sign.crt      証明書  PCの信頼された発行元へ登録
 
 ./ca/issued/ore-code-sign.pfx      コードを作成するユーザのみ 個人の証明書欄へインストール時に証明書作成時のパスワード入力必要

