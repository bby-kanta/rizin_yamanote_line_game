# RIZIN選手名山手線ゲーム

RIZIN選手名を使った山手線ゲームを支援するWebアプリケーション。
リアルタイムで選手名を記録し、重複や言い忘れを防ぐことで、ゲームの公平性を保ちます。

## 技術スタック

- **Backend**: Ruby on Rails 8.0.2
- **Database**: MySQL 8
- **Frontend**: Rails標準テンプレート（ERB）+ Stimulus.js
- **Authentication**: Devise
- **Containerization**: Docker + Docker Compose

## 開発環境のセットアップ

### 前提条件
- Docker
- Docker Compose

### 1. リポジトリクローン
```bash
git clone <repository-url>
cd rizin_yamanote_line_game
```

### 2. Dockerコンテナ起動
```bash
docker compose up -d
```

### 3. 依存関係のインストール
```bash
docker compose exec web bundle install
```

### 4. データベース作成・マイグレーション
```bash
docker compose exec web rails db:create
docker compose exec web rails db:migrate
```

### 5. アプリケーションにアクセス
- **Rails Application**: http://localhost:3333
- **MySQL Database**: mysql://localhost:3306

## 開発用コマンド

### 基本操作
```bash
# コンテナ起動
docker compose up -d

# コンテナ停止
docker compose down

# ログ確認
docker compose logs -f web

# Railsコンソール
docker compose exec web rails console

# bundle install（新しいgemを追加した後）
docker compose exec web bundle install

# マイグレーション実行
docker compose exec web rails db:migrate

# テスト実行
docker compose exec web rails test
```

### データベース操作
```bash
# MySQL接続（外部から）
mysql -h 127.0.0.1 -P 3306 -u root -ppassword app_development

# Railsコンテナ内からMySQL接続
docker compose exec web mysql -h db -u root -ppassword app_development

# データベースリセット
docker compose exec web rails db:drop db:create db:migrate
```

## データベース接続情報

### 開発環境
- **Host**: localhost (外部から) / db (コンテナ内から)
- **Port**: 3306
- **Username**: root
- **Password**: password
- **Database**: app_development

## アーキテクチャ

### ゲーム機能
- ✅ **ユーザー認証**: Deviseによる登録・ログイン
- 🚧 **ゲームセッション**: セッション作成・参加機能
- 🚧 **選手名検索**: ひらがな入力でのインクリメンタルサーチ
- 🚧 **リアルタイム同期**: Action Cableを使用
- 🚧 **ターン制管理**: 順番制御と勝敗判定

### データモデル
```
User (ユーザー)
├── name (名前)
├── email (メールアドレス)
└── password (パスワード)

GameSession (ゲームセッション) [TODO]
├── name (セッション名)
├── code (参加コード)
├── host_user_id (ホスト)
└── status (状態)

Fighter (選手データ) [TODO]
├── full_name (漢字名)
├── full_name_hiragana (ひらがな名)
└── is_active (現役フラグ)
```

## 今後の実装予定

### Phase 1 (MVP)
- [ ] ゲームセッション機能
- [ ] 選手データモデル
- [ ] RIZIN公式サイトからのスクレイピング
- [ ] インクリメンタルサーチ機能
- [ ] リアルタイム同期

### Phase 2
- [ ] 統計機能
- [ ] UI/UX改善
- [ ] パフォーマンス最適化

## トラブルシューティング

### よくある問題

#### ポートが使用中の場合
```bash
# 使用中のポートを確認
lsof -i :3333
lsof -i :3306

# docker-compose.ymlのポート番号を変更
```

#### データベース接続エラー
```bash
# MySQLコンテナの状態確認
docker compose ps

# MySQLログ確認
docker compose logs db

# データベース再作成
docker compose down -v
docker compose up -d
```

#### bundle installエラー
```bash
# コンテナ再ビルド
docker compose build --no-cache web
docker compose up -d
```

## ライセンス
MIT License

## 貢献方法
1. このリポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add some amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成