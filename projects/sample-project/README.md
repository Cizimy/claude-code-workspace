# Sample Project

Claude Code ワークスペース統合のデモンストレーション用プロジェクト

## プロジェクト設定

### Claude Code 統合設定
- **継承設定**: ワークスペースの`.claude/settings.json`を継承
- **プロジェクト固有Hook**: `.claude/hooks_local/`配下に配置
- **テスト実行**: プロジェクト固有のテストランナー

### ファイル構成
```
sample-project/
├── .claude/
│   ├── settings.json          # 継承設定
│   └── hooks_local/           # プロジェクト固有Hook
├── src/                       # ソースコード
├── tests/                     # テストコード
├── package.json               # 依存関係
└── README.md                  # このファイル
```

## 技術スタック
- **言語**: JavaScript/TypeScript
- **テスト**: Jest
- **品質管理**: ESLint, Prettier
- **CI**: GitHub Actions

## 開発ワークフロー
1. GitHub Issue作成
2. `/project:new-feature [issue_number]` でClaude開発開始
3. TDD サイクルによる実装
4. Hook による品質チェック
5. PR作成・レビュー・マージ

*このプロジェクトは設定デモ用です*