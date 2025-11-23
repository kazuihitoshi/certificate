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
|1.で作成されたファイル<br>./ca/certs/ca.crt RootCA| /var/lib/samba/private/tls/ca.pem | PCの信頼されたルート証明機関へインストール | |

### 4 コードサイン

```bash
./codesign-cert.sh ore-code-sign password [有効日数]
```
- 生成されるファイル

|作成されるファイル | サーバ用途  | PC証明書インストール | 備考 |
|-----------------|-------------|--------------|------|
|./ca/keys/ore-code-sign.key.pem  秘密鍵|特になし |特になし | |
|./ca/issued/ore-code-sign.crt 証明書 |特になし | PCの信頼された発行元へ登録| |
|./ca/issued/ore-code-sign.pfx|特になし|マクロを作成するユーザの個人の証明書欄へインストール。<br>インストールの際に証明書作成時のパスワード入力必要| |

#### Active Directoryによる証明書の一括配布方法

1. 信頼されたルートCA証明書の配布（全PCに必須）
マクロに署名した証明書の発行元CAの証明書 (ca.pem または ca.crt) を、全クライアントPCの「信頼されたルート証明機関」ストアに配布します。

 - (1) GPO管理コンソールの起動:
    
    Windowsのクライアントまたは管理サーバーからグループポリシー管理エディターを開きます。
 - (2) ポリシーの場所:
   
   コンピューターの構成 → ポリシー → Windows の設定 → セキュリティの設定 → 公開キーのポリシー → 信頼されたルート証明機関

 - (3) CA証明書のインポート:
   
   信頼されたルート証明機関 を右クリックし、「インポート」を選択します。

   インポートウィザードで、CA証明書ファイル（.crt または .cer 形式に変換したもの）を指定し、インポートを完了させます。<br>
   これにより、ドメインに参加している全PCは、CAが発行した証明書（コード署名証明書含む）を、有効なものとして認識するようになります。

2. 信頼された発行元への署名証明書の配布（必須）

   マクロに署名したエンドエンティティ証明書（Fuji-Techno Macro Sign）を、全クライアントPCの「信頼された発行元」ストアに配布します。

- (1) ポリシーの場所:
   
  コンピューターの構成 → ポリシー → Windows の設定 → セキュリティの設定 → 公開キーのポリシー → 信頼された発行元

- (2) 署名証明書のインポート:
  
  信頼された発行元 を右クリックし、「インポート」を選択します。
  
  インポートウィザードで、マクロ署名に使用した証明書ファイル（.crt または .cer 形式）を指定し、インポートを完了させます。
  