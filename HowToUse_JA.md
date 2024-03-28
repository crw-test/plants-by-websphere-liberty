WebSphereで動作するサンプルJavaアプリケーション「Plants by WebSphere」をさまざまな実行環境で動かすためのサンプルです。  
次の環境（Windows11 Enterprise、Podman 4.6.2）で動作を確認しています。  
    
# Plants by WebSphere アプリケーションの概要
オンラインショッピングサイトのイメージで、商品一覧、カート投入、ユーザー新規登録、ログインなどの機能を持ちます。  
  
## アプリケーション構成
- アプリケーション層
  - tWASまたはLiberty  
- データ層
  - Db2またはMariaDB  

アプリケーション層とデータ層は、tWASｰMariaDB以外の組合せが可能です。  
このサンプル手順は永続化を想定しないため、生成したコンテナが削除されたタイミングでデータ層に記録した情報は喪失します。  
  
# ローカルのコンテナ環境で動かすための手順
次の流れで準備します。  
- 環境準備
- DBコンテナの起動
- DBセットアップ
- アプリコンテナの起動
- アプリへのアクセス
- アプリから初期データ投入
  
## 環境準備
各準備作業の詳細な手順は、各種Webサイトなどをご確認ください。
- 作業者のGitHubアカウントに当リポジトリをフォーク
- DBeaver（または任意のDBアクセスツール）のインストール
- Podmanインストール
- ローカルマシンにフォークしたリポジトリのクローン作成

## DBコンテナの起動
Db2またはMariaDBのいずれかを選択して手順を進めます。  
アプリケーションはどちらを選択しても動作します。MariaDBのほうが待ち時間は短いですがDB追加のコマンドを叩く必要があります。

### Db2コンテナ起動
env_list.txtの設定ファイルを使用して起動します。ポートは50000です。  
  
カレントフォルダをクローンのルートに変更して、Db2イメージをrunします。
```
podman run -h db2server --name db2pod --restart=no --detach --privileged=true -p 50000:50000 --env-file docker\Db2\env_list.txt icr.io/db2_community/db2
```

完了までに時間がかかるため、進捗状況確認が必要な場合はこちらでログを参照してください。
```
podman logs -f db2pod
```

参考として、Pod内の起動状況確認の手順です。
```
podman exec -ti db2pod bash -c "su db2inst1"
db2 CONNECT TO PLANTSDB USER db2inst1 USING password
```

### MySQLコンテナ起動
標準的なインストールを行ないます。ポートは3306です。
```
podman run -d -p 3306:3306 -e MYSQL_ROOT_PASSWORD=rootpwd --name mariapod mariadb:10.3
```

次のコマンドでデータベースの追加を行ないます。
```
podman exec -it mariapod bash
mysql -u root -p
create database plantsdb;
```

## DBセットアップ

### DBeaver接続
選択したDBの設定にあわせて、接続を確立します。  
接続後に、plantsdbデータベースでテーブル生成の初期スクリプト（クローンフォルダ\docker\mariadb\init.sql）を実行してください。

## アプリコンテナの起動

### ローカルでのアプリケーションコンテナ起動（Liberty）
次のファイルにDB接続情報の記載があるため、接続先にあわせた修正を行ないます。
接続先DB向けの記述をアンコメントし、接続しないDB向けの記述をコメントアウトします。
- Dockerfile
- wlp/config/server.xml

カレントフォルダをクローンのルートに変更して次のコマンドを実行し、アプリコンテナのイメージを作成します。
```
(MySQL)
podman build -t plants_liberty --env DB_PASSWORD=rootpwd --env DB_PORT=3306 --env DB_HOST=localhost --env DB_USER=root .
```
```
(Db2)
podman build -t plants_liberty --env DB_PASSWORD=password --env DB_PORT=50000 --env DB_HOST=localhost --env DB_USER=db2inst1 .
```

ビルドしたコンテナイメージを実行します。
```
podman run --name plantspod_liberty -e DB_HOST=host.containers.internal -p 9080:9080 plants_liberty
```

### ローカルでのアプリケーションコンテナ起動（tWAS）
カレントフォルダをクローンのルートに変更して次のコマンドを実行し、アプリコンテナのイメージを作成します。
```
podman build -t plants_twas -f docker\twas\Containerfile .
```

ビルドしたコンテナイメージを実行します。
```
podman run --name plantspod_twas -p 9080:9080 -p 9043:9043 plants_twas
```

起動が完了したら、別のコマンドプロンプトから管理コンソールのパスワードを確認します。
```
podman exec -it plantspod_twas bash
cat /tmp/PASSWORD
```

ブラウザから管理コンソールにログインしてDB接続に関する設定を行ないます。  
https://localhost:9043/admin  
ユーザーはwsadmin、パスワードは上で確認したテキスト  

tWASの管理コンソールで次の設定を行ないます。

```
以下の設定操作時に
　Changes have been made to your local configuration. 
のメッセージが表示されたら、
　「Save directly to the master configuration.」
のメッセージにあるリンクをクリックする。


Security > Global security
　Autentication > Java Authentication and Authorization Service > J2C authentication data
　　New...
　　Alias -> Db2Account
　　User Id -> db2inst1
　　password -> password

Resources＞JDBC＞JDBC providers
　AllScopes → Node=DefaultNode01, Server=server1
　New
　　Database type -> DB2
　　Provider type -> DB2 Universal JDBC Driver Provider
　　Implementaion type -> Connection pool data source
　　Name -> db2-liberty

　　Classpath -> ${DB2UNIVERSAL_JDBC_DRIVER_PATH}/db2jcc4.jar (db2jcc.jar -> db2jcc4.jar)
　　※ このフィールドは個別にapplyボタンを持つため、押しておく
　　Directory location for ... ${DB2UNIVERSAL_JDBC_DRIVER_PATH}
　　　-> /opt/IBM/WebSphere/AppServer/universalDriver/lib

　他はデフォルトで画面を先に進めて終了

Resources＞JDBC＞Data sources
　AllScopes → Node=DefaultNode01, Server=server1
　New
　　Data source name -> pbw
　　JNDI name -> jdbc/PlantsByWebSphereDataSource
　　Select an existing JDBC Provider -> db2-liberty
　　Database name -> plantsdb
　　Server name -> host.containers.internal
　　Port number -> 50000

　　Component-managed authentication alias -> Db2Account

　他はデフォルトで画面を先に進めて終了

Applications -> New Application -> New Enterprise Application
　ローカルで作成済earファイル（クローンフォルダ\target\plants-by-websphere-jee6-mysql.ear）を指定する

　他はデフォルトで最後まで進める
　saveのリンクが表示されたら、リンククリックする

Applications -> Application Types -> WebSphere enterprise Application
　pbw-earを選択し、Startボタンをクリックする
　Application Status が緑色の矢印に置き換わる
```

### アプリへのアクセス
ブラウザから次のURLにアクセスします。  
http://localhost:9080

### アプリから初期データ投入
初期状態ではデータ層にデータが入っていないため、商品データが参照できません。DBのリセット処理を行ない商品データの登録を行ないます。  
アプリ画面右上の「HELP」リンクをクリックし、「Reset database」ボタンをクリックしてください。

### 環境の再起動
上記手順でコンテナは作成されているため、端末再起動した後などにアプリケーションを再度立ち上げる場合は既存のDBコンテナとアプリコンテナを開始することで元の状態に戻ります。
```
podman start xxxx
```
xxxxには各コンテナの名前が入ります。
- Db2
  - db2pod
- MariaDB
  - mariapod
- Liberty
  - plantspod_liberty
- tWAS
  - plantspod_twas

