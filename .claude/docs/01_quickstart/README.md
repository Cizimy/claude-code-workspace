# 🚀 クイックスタートガイド

> **目標**: TDD × YAGNI × 自動ガードを効かせた Claude Code 開発フローを「再現性高く」回せる状態にする

## 📋 セットアップ全体像

### Phase 1: 基盤構築 (Day 0-2)
- **[環境セットアップ](environment_setup.md)** - リポジトリ、権限、基本設定
- 完了目安: 新人の PC で 1 時間以内に再現可能

### Phase 2: ガバナンス整備 (Day 3-4)  
- **[ガバナンス設定](governance_setup.md)** - 議事録管理、意思決定記録
- 完了目安: CI で自動チェック機能

### Phase 3: プロジェクト統合 (Day 5-6)
- **[プロジェクト設定](project_setup.md)** - 個別プロジェクトの配置・設定
- 完了目安: 複数プロジェクトの並行管理

### Phase 4: AI 自動化 (Day 7)
- **[テンプレート設定](template_setup.md)** - Claude コマンド・テンプレート
- 完了目安: `/project:new-feature` コマンド実行可能

### Phase 5: 実証・運用開始 (Day 8-10)
- **[パイロットテスト](pilot_testing.md)** - 実際の開発タスクでの検証
- 完了目安: 自動 PR 生成・Hook による品質管理確認

## ⚡ 推奨実行順序

**新規環境の場合:**
1. [環境セットアップ](environment_setup.md) → 基本的な Claude Code 環境を構築
2. [ガバナンス設定](governance_setup.md) → 議事録・意思決定の仕組み整備  
3. [プロジェクト設定](project_setup.md) → 既存プロジェクトの統合
4. [テンプレート設定](template_setup.md) → AI 自動化の準備
5. [パイロットテスト](pilot_testing.md) → 実際の開発での検証

**既存環境の改善:**
- 目的に応じて必要な Phase のみ実施
- 既存設定との衝突に注意

## 🎯 各 Phase の成果物

| Phase | 主要成果物 | 確認方法 |
|-------|-----------|----------|
| 1 | `.claude/settings.json`, hooks, GitHub Actions | CI green |
| 2 | `governance/adr/`, decision_log | ADR validation |
| 3 | `projects/*/` worktree 配置 | プロジェクト個別 CI |
| 4 | `.claude/commands/` テンプレート | コマンド実行テスト |
| 5 | 実動作確認 | 自動 PR 生成・Hook 実行 |

## 🔧 進行のコツ

### 効率的な進め方
1. **「README → CLAUDE.md → hooks」から書く** - 人も AI もまずそこを見る
2. **Hook は小さく作って即ブロック** - 後で緩める方が安全
3. **ADR で決定事項を可視化** - 変更理由が残ると Claude.md 更新も迷わない
4. **PR 粒度を守る** - 1 Issue = 1 PR、一度に大きくしない
5. **失敗ログを残す** - Claude がどこで転けたかを Hooks でサマリ出力

### よくある問題と対策
- **権限エラー** → GitHub Secrets の設定確認
- **Hook 実行失敗** → 実行権限・シェバン確認  
- **CI エラー** → ワークフロー設定の構文チェック
- **worktree 問題** → リモート URL 設定確認

## ✅ 完了定義

**最終的に以下が動作すること:**
- `workspace` で `gh repo clone && code .` した直後に
  - Dev Container が立ち上がり
  - `/project:new-feature` が動き  
  - Hooks & CI がグリーンで流れる

この状態を **新人の PC で 1 時間以内に再現できる** ことが目標です。

---

**次のステップ**: [環境セットアップ](environment_setup.md) から開始してください。