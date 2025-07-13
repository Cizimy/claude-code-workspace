# 📁 推奨ドキュメント構成テンプレート

> **目的**: AI駆動開発環境に最適化されたドキュメント構造の標準テンプレート

## 🎯 設計指針

### 3つの基本原則
1. **プロジェクト憲法（CLAUDE.md）と実行ガード（Hooks）を軸に据える**
2. **"How-to" と "Why" を分離** - 手順書は最短経路で / 背景や判断基準は解説ドキュメントへ
3. **"生きた文書" と "固定リファレンス" を区別** - 更新頻度に応じた置き場所でメンテ容易に

### 対象環境
- Claude Code を中心とした AI 駆動開発
- TDD × YAGNI × 自動ガード の徹底
- 迷わず再現・運用可能な環境構築

## 📂 標準ディレクトリ構造

### 基本構成
```
project_root/
├── README.md                   # 最小限の概要とリンク集
├── CLAUDE.md                   # プロジェクト憲法（AI が最優先で読む）★
├── docs/                       # MkDocs などでサイト化を想定
│   ├── 00_introduction/
│   │   └── project_overview.md # 目的・非目標・ビジョン
│   ├── 10_architecture/
│   │   ├── system_arch.md      # 全体構成図 & サービス間 I/F
│   │   └── data_flow.md        # Context→Tools→Permission→Execution→Feedback
│   ├── 20_environment/
│   │   ├── local_setup.md      # OS/CLI/エディタ設定チェックリスト
│   │   ├── container_setup.md  # Dev Container & Dockerfile
│   │   └── cloud_prereq.md     # GitHub 権限・Secrets 登録手順
│   ├── 30_ai_workflow/
│   │   ├── claude_workflow.md  # Action 起動〜PR 完遂までのタイムライン
│   │   ├── hooks.md            # Hook 種別・発火条件・失敗時挙動
│   │   ├── commands.md         # /project:new-feature 等テンプレと拡張法
│   │   └── allowed_tools.md    # Claude に許可／禁止するツール一覧
│   ├── 40_quality/
│   │   ├── tdd_guidelines.md   # テスト先行ルール & 失敗例集
│   │   ├── yagni_policy.md     # YAGNI 禁則リスト・判断フロー
│   │   ├── coverage.md         # カバレッジ閾値と測定方法
│   │   └── lint_and_style.md   # Lint/Formatter 設定の根拠と例
│   ├── 50_ci_cd/
│   │   ├── pipeline.md         # CI ステージ / 条件付きジョブ一覧
│   │   ├── security_scans.md   # SCA / SAST 連携手順
│   │   └── release_process.md  # タグ付け・自動デプロイ
│   ├── 60_process/
│   │   ├── issue_template.md   # "期待テスト必須" テンプレ
│   │   ├── pr_template.md      # 変更概要 + カバレッジ差分
│   │   └── branching_model.md  # main / feature / hotfix 戦略
│   └── 99_glossary.md          # 用語集（AI, Hook, TDD …）
├── .github/
│   ├── workflows/
│   │   ├── claude.yml          # Claude Code Action 定義
│   │   └── ci.yml              # 通常 CI
│   └── ISSUE_TEMPLATE/         # Issue テンプレート
└── .claude/
    ├── settings.json           # allowedTools, hookPaths
    ├── commands/               # スラッシュコマンド群
    ├── hooks/                  # 品質管理 Hook
    └── prompts/                # 再利用プロンプト
```

## 📋 各レイヤーの詳細

### レイヤー 0: プロジェクト基盤
| ファイル | 役割 | 更新頻度 | 重要度 |
|----------|------|----------|--------|
| `README.md` | 最初の入口・概要 | 低 | ⭐⭐⭐ |
| `CLAUDE.md` | AI の行動指針 | 中 | ⭐⭐⭐⭐⭐ |

### レイヤー 1: イントロダクション (00_)
| ファイル | 内容 | 対象読者 |
|----------|------|----------|
| `project_overview.md` | プロジェクトの目的・スコープ・ビジョン | 新規参加者・ステークホルダー |

### レイヤー 2: アーキテクチャ (10_)
| ファイル | 内容 | 対象読者 |
|----------|------|----------|
| `system_arch.md` | 全体構成・コンポーネント図・責務分離 | 開発者・アーキテクト |
| `data_flow.md` | Claude Code の動作フロー・Hook 連携 | AI開発担当者 |

### レイヤー 3: 環境構築 (20_)
| ファイル | 内容 | 対象読者 |
|----------|------|----------|
| `local_setup.md` | 開発環境セットアップ手順 | 新規開発者 |
| `container_setup.md` | Docker・Dev Container 設定 | DevOps・新規開発者 |
| `cloud_prereq.md` | クラウド・CI設定手順 | DevOps・管理者 |

### レイヤー 4: AI ワークフロー (30_)
| ファイル | 内容 | 対象読者 |
|----------|------|----------|
| `claude_workflow.md` | Claude Code の具体的な使用方法 | 全開発者 |
| `hooks.md` | Hook システムの技術詳細 | Hook開発者 |
| `commands.md` | カスタムコマンドの作成・使用 | 上級ユーザー |
| `allowed_tools.md` | ツール権限管理・セキュリティ | 管理者 |

### レイヤー 5: 品質管理 (40_)
| ファイル | 内容 | 対象読者 |
|----------|------|----------|
| `tdd_guidelines.md` | TDD実践のガイドライン・失敗例 | 全開発者 |
| `yagni_policy.md` | YAGNI原則の適用基準・判断フロー | 全開発者 |
| `coverage.md` | テストカバレッジの測定・改善 | QA・開発者 |
| `lint_and_style.md` | コーディング規約・ツール設定 | 全開発者 |

### レイヤー 6: CI/CD (50_)
| ファイル | 内容 | 対象読者 |
|----------|------|----------|
| `pipeline.md` | CI パイプラインの構成・ジョブ詳細 | DevOps・開発者 |
| `security_scans.md` | セキュリティスキャンの設定・運用 | セキュリティ・DevOps |
| `release_process.md` | リリース手順・デプロイ自動化 | リリース担当者 |

### レイヤー 7: プロセス (60_)
| ファイル | 内容 | 対象読者 |
|----------|------|----------|
| `issue_template.md` | Issue作成の標準テンプレート | 全開発者 |
| `pr_template.md` | PR作成の標準テンプレート | 全開発者 |
| `branching_model.md` | ブランチ戦略・マージルール | 全開発者 |

## 🔧 カスタマイズガイド

### プロジェクト規模別の調整

#### 小規模プロジェクト (個人〜3人)
```
# 最小構成
├── README.md
├── CLAUDE.md  
├── docs/
│   ├── 20_environment/local_setup.md
│   ├── 30_ai_workflow/claude_workflow.md
│   └── 40_quality/tdd_guidelines.md
└── .claude/
    ├── settings.json
    └── hooks/
```

#### 中規模プロジェクト (4-10人)
```
# 標準構成 (推奨テンプレート通り)
# 全レイヤーを実装
```

#### 大規模プロジェクト (10人以上)
```
# 拡張構成
├── docs/
│   ├── 70_team_process/     # チーム固有プロセス
│   ├── 80_integration/      # 他システム連携
│   └── 90_operations/       # 運用・監視
```

### 技術スタック別の調整

#### Python プロジェクト
```yaml
# 追加ファイル例
docs/40_quality/
├── pytest_config.md        # pytest 設定詳細
├── type_checking.md        # mypy・型チェック
└── package_management.md   # pip・poetry 管理
```

#### Node.js プロジェクト
```yaml
# 追加ファイル例  
docs/40_quality/
├── jest_config.md          # Jest 設定詳細
├── typescript_config.md    # TypeScript 設定
└── npm_scripts.md          # npm scripts 標準化
```

#### Multi-language プロジェクト
```yaml
# 言語別サブディレクトリ
docs/40_quality/
├── python/
├── nodejs/
└── shared/                 # 共通品質基準
```

## 📊 実装チェックリスト

### Phase 1: 基盤構築
- [ ] README.md 作成 (プロジェクト概要・リンク集)
- [ ] CLAUDE.md 作成 (AI 行動指針・制約)
- [ ] .claude/settings.json 作成 (基本設定)

### Phase 2: 環境・ワークフロー
- [ ] docs/20_environment/ 作成 (環境構築手順)
- [ ] docs/30_ai_workflow/ 作成 (Claude 使用方法)
- [ ] .claude/hooks/ 作成 (品質ガード)

### Phase 3: 品質・プロセス
- [ ] docs/40_quality/ 作成 (品質基準・測定)
- [ ] docs/60_process/ 作成 (開発プロセス)
- [ ] .github/ISSUE_TEMPLATE/ 作成

### Phase 4: CI/CD・運用
- [ ] docs/50_ci_cd/ 作成 (パイプライン詳細)
- [ ] .github/workflows/ 作成 (自動化設定)
- [ ] 運用開始・継続改善

## 🔄 継続的改善

### 文書品質の維持
- **リンク切れチェック**: CI で自動検証
- **内容の最新性**: 四半期ごとの見直し
- **利用状況分析**: アクセス頻度・フィードバック収集

### テンプレートの進化
- **新しいベストプラクティス**: 他プロジェクトからの学習
- **ツールの更新**: Claude Code・周辺ツールのアップデート対応
- **チームの成長**: 習熟度に応じた文書レベル調整

---

**適用指針**: このテンプレートをベースに、プロジェクトの特性・チーム規模・技術スタックに応じてカスタマイズしてください。重要なのは一貫性と継続的な改善です。