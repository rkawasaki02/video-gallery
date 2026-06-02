# VideoGarage

> 複数の動画プラットフォームを横断してブックマークできる、フルサーバーレス構成の個人用動画ギャラリー

🔗 **https://videogarage.jp**

![アーキテクチャ図](./docs/architecture.png)

---

## 目次

- [プロジェクト概要](#プロジェクト概要)
- [なぜ作ったか](#なぜ作ったか)
- [主な機能](#主な機能)
- [使用技術](#使用技術)
- [アーキテクチャ](#アーキテクチャ)
- [技術的な意思決定](#技術的な意思決定)
- [データ設計](#データ設計)
- [苦労した点と解決](#苦労した点と解決)
- [Roadmap](#roadmap)

---

## プロジェクト概要

YouTube・Vimeo・Twitch・mp4直リンクなど、複数プラットフォームの動画URLを登録してタブごとに整理できるWebアプリです。AWSのマネージドサービスを組み合わせたフルサーバーレス構成で、認証・データ保存・配信までをクラウド上で完結させています。

アカウント登録なしのゲストモードでもすぐ使え、ログインするとデータがクラウドに同期されます。

---

## なぜ作ったか

「見たい動画があちこちのプラットフォームに散らばっていて、一覧で管理したい」という個人的な課題から出発しました。

技術的には、**クラウドエンジニアとしてAWSのサーバーレスアーキテクチャを設計から実装まで一気通貫で経験する**ことを目的にしています。フロントエンドの作り込みよりも、認証・API・データ層・インフラの設計判断に重点を置いています。

---

## 主な機能

| 機能 | 説明 |
|------|------|
| マルチプラットフォーム対応 | YouTube / Vimeo / Twitch / mp4直リンクをURL判定で自動振り分け |
| プレビュー再生 | ホバーでミュート再生、クリックで固定再生 |
| タブ管理 | 動画をタブ単位でカテゴリ分け（作成・リネーム・削除） |
| 並び替え | ドラッグ＆ドロップ（PC・スマホ両対応） |
| ゲスト / ログイン | 未ログインはローカル保存、ログインでクラウド同期 |
| データ移行 | ゲスト時のデータをログイン時に自動でクラウドへ移行 |

---

## 使用技術

### フロントエンド
![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=flat&logo=javascript&logoColor=black)
![HTML5](https://img.shields.io/badge/HTML5-E34F26?style=flat&logo=html5&logoColor=white)
![CSS3](https://img.shields.io/badge/CSS3-1572B6?style=flat&logo=css3&logoColor=white)

- バニラJavaScript（フレームワーク非依存）
- プラットフォーム判定ロジックをモジュール分離（`platform.js`）

### バックエンド / インフラ
![AWS Lambda](https://img.shields.io/badge/AWS%20Lambda-FF9900?style=flat&logo=awslambda&logoColor=white)
![Amazon DynamoDB](https://img.shields.io/badge/DynamoDB-4053D6?style=flat&logo=amazondynamodb&logoColor=white)
![Amazon Cognito](https://img.shields.io/badge/Cognito-DD344C?style=flat&logo=amazoncognito&logoColor=white)
![Amazon API Gateway](https://img.shields.io/badge/API%20Gateway-FF4F8B?style=flat&logo=amazonapigateway&logoColor=white)
![Python](https://img.shields.io/badge/Python%203.14-3776AB?style=flat&logo=python&logoColor=white)

| サービス | 役割 |
|----------|------|
| Cognito | ユーザー認証（JWTトークン発行） |
| API Gateway | HTTP API・JWTオーソライザーによる認可 |
| Lambda | Python製のCRUD処理（動画・タブ各3関数） |
| DynamoDB | ユーザーデータの永続化 |
| S3 + CloudFront | 静的フロントエンドの配信 |
| Route53 + ACM | 独自ドメイン・HTTPS化 |

---

## アーキテクチャ

```
                    ┌──────────────┐
   Users ─────────► │   Route53    │
                    └──────┬───────┘
                           ▼
                    ┌──────────────┐      ┌──────────┐
                    │  CloudFront  │ ───► │    S3    │
                    └──────────────┘      └──────────┘
                           │
   Users ──► Cognito       ▼
     │      (認証)   ┌──────────────┐    ┌──────────┐    ┌────────────┐
     └────JWT──────►│ API Gateway  │──► │  Lambda  │──► │  DynamoDB  │
                    └──────────────┘    └──────────┘    └────────────┘
                      JWTオーソライザー    Python 3.14     シングルテーブル
```

---

## 技術的な意思決定

### DynamoDB vs RDS
**DynamoDBを選択。** データ構造が「ユーザーに紐づく動画・タブ」というシンプルなキー設計で、リレーションが不要なため。RDSはLambdaとのコネクション管理が煩雑になり、最小構成でも固定費が発生する。DynamoDBはオンデマンド課金でアクセスがなければコストゼロに近く、サーバーレスとの親和性が高い。

### シングルテーブル設計
全ユーザーのデータを1テーブルに格納し、`userId`をパーティションキーにすることでユーザー単位にデータを論理分離。テーブルをユーザーごとに分ける運用コストを避け、パーティション分散による高速な検索を実現している。

### 認証の責務分離
API GatewayのJWTオーソライザーでトークン検証を完結させ、Lambda側には認証ロジックを持たせない設計。Lambdaは検証済みの`sub`（ユーザーID）を受け取るだけなので、各関数の責務がCRUDに集中する。

### 最小権限の原則（IAM）
Lambda関数ごとに必要なActionのみを許可。

| 関数 | 許可するAction |
|------|---------------|
| get系 | `dynamodb:Query` |
| post系 | `dynamodb:PutItem`, `dynamodb:Query` |
| delete系 | `dynamodb:DeleteItem`, `dynamodb:Query`, `dynamodb:BatchWriteItem` |

### ゲストモードの設計
未ログインでもlocalStorageで全機能が使えるようにし、参入障壁を下げた。ログイン時にはローカルデータをDynamoDBへ移行する処理を実装し、ゲストからの移行体験を損なわないようにしている。

---

## データ設計

### videogarage-videos
| 項目 | 型 | 説明 |
|------|-----|------|
| userId | String | パーティションキー（Cognito sub） |
| videoId | String | ソートキー |
| url | String | 動画URL |
| type | String | プラットフォーム種別 |
| tabId | String | 所属タブ |
| title | String | タイトル |
| addedAt | Number | 追加日時 |
| order | Number | 並び順 |

### videogarage-tabs
| 項目 | 型 | 説明 |
|------|-----|------|
| userId | String | パーティションキー（Cognito sub） |
| tabId | String | ソートキー |
| name | String | タブ名 |
| createdAt | Number | 作成日時 |

---

## 苦労した点と解決

### 1. CORSエラーによるAPI通信の失敗
フロントからAPI Gatewayへのリクエストが`Access-Control-Allow-Origin`不足でブロックされた。API GatewayのCORS設定で`Allow-Headers`にURLを誤設定していたことが原因で、`Authorization, Content-Type`に修正して解決。プリフライトリクエストの仕組みを理解するきっかけになった。

### 2. Decimal型のJSONシリアライズエラー
DynamoDBは数値を`Decimal`型で返すため、`json.dumps()`がそのまま変換できずLambdaが500を返した。`json.JSONEncoder`を継承したカスタムエンコーダーを実装して解決。

### 3. サインインのたびにタブが重複生成される
ページ読み込み時にデフォルトタブを作成 → ログイン時にそれがマイグレーションされ続ける、という無限増殖バグが発生。デフォルトタブの生成をログイン状態の判定後に移動することで、状態管理の責務を整理して解決。

### 4. 同一URLの動画が別タブで競合する
動画の一意キー（uid）をURLベースで生成していたため、別タブに同じ動画を追加すると同一扱いになり削除が連動してしまった。uidに乱数を付与してインスタンス単位でユニーク化し、重複チェックは`id + tabId`で行うよう分離した。

---

## Roadmap

| 項目 | ステータス | 内容 |
|------|-----------|------|
| Terraform化 | 🚧 実装中 | 全AWSリソースをIaC化し、`terraform apply`で環境を再現可能にする |
| CI/CD | 📋 予定 | GitHub Actionsで`main`マージ時にS3・Lambdaへ自動デプロイ |
| 未対応URLの動的承認 | 📋 予定 | 未対応プラットフォームのURLをSlackに通知し、承認制で許可リストに追加 |

---

## 開発運用

- **Conventional Commits** に準拠したコミットメッセージ（日本語）
- **feature ブランチ + Squash Merge** によるGitフロー
- **GitHub Issues** でタスク管理
