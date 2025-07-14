# AI完璧主義症候群 監視・運用手順書

> **目的**: AI完璧主義防止システムの日常運用における監視・対応・改善手順

## 📋 概要

### 監視対象
- **大量ドキュメント作成**: 5ファイル以上の同時作成検出
- **長期計画策定**: 2026年以降の推測的計画検出
- **過剰詳細化**: 500行超の大量文書作成検出
- **憲法原則逸脱**: YAGNI・TDD・シンプル設計からの乖離

### システム構成
```
Constitution Guard Hook → 違反検出 → 教育的ブロック → ログ記録 → 統計分析
```

## 🔍 日常監視手順

### 1. システム状態確認（毎日）

#### Hook動作確認
```bash
# Hook実行権限確認
ls -la .claude/hooks/pre-tool/constitution-guard.sh

# 最新ログ確認
tail -20 /tmp/claude-hooks.log | grep "constitution-guard"

# 違反統計確認
tail -10 /tmp/constitution-violations.jsonl
```

#### 期待される正常出力
```
-rwxr-xr-x 1 user user 15234 Jul 14 10:30 constitution-guard.sh
[2025-07-14 10:30:15] [constitution-guard.sh] Constitution Guard activated: tool=Edit
[2025-07-14 10:30:15] [constitution-guard.sh] File is exempt from constitution checks
```

### 2. 違反パターン分析（毎日）

#### 違反ログの確認
```bash
# 当日の違反件数
grep "$(date '+%Y-%m-%d')" /tmp/constitution-violations.jsonl | wc -l

# 違反タイプ別集計
grep "$(date '+%Y-%m-%d')" /tmp/constitution-violations.jsonl | \
  jq -r '.violation' | sort | uniq -c

# 詳細な違反内容確認
grep "$(date '+%Y-%m-%d')" /tmp/constitution-violations.jsonl | \
  jq -r '"\(.timestamp) [\(.violation)] \(.context)"'
```

#### 正常な運用状態
- **違反件数**: 1日あたり0-2件
- **主要違反**: `excessive_detail` が60%、`bulk_document_creation` が30%
- **異常パターン**: 同一違反の3回以上連続発生

### 3. 効果測定（週次）

#### KPI収集スクリプト
```bash
#!/bin/bash
# ai_perfectionism_kpi.sh - 週次効果測定

WEEK_START=$(date -d "7 days ago" '+%Y-%m-%d')
TODAY=$(date '+%Y-%m-%d')

echo "=== AI完璧主義防止システム 週次KPI ==="
echo "期間: $WEEK_START 〜 $TODAY"
echo ""

# 1. 違反検出率
TOTAL_VIOLATIONS=$(grep -c "$WEEK_START\|$TODAY" /tmp/constitution-violations.jsonl 2>/dev/null || echo "0")
echo "1. 違反検出件数: $TOTAL_VIOLATIONS件"

# 2. 違反タイプ別分布
echo "2. 違反タイプ別分布:"
grep "$WEEK_START\|$TODAY" /tmp/constitution-violations.jsonl 2>/dev/null | \
  jq -r '.violation' | sort | uniq -c | \
  awk '{printf "   %s: %d件\n", $2, $1}'

# 3. ドキュメント作成削減効果
BULK_VIOLATIONS=$(grep "bulk_document_creation" /tmp/constitution-violations.jsonl 2>/dev/null | wc -l)
echo "3. 大量ドキュメント作成阻止: ${BULK_VIOLATIONS}回"

# 4. 平均対応時間（Hook実行からツール再実行まで）
echo "4. 平均違反対応時間: [手動測定必要]"

echo ""
echo "=== 推奨アクション ==="
if [[ $TOTAL_VIOLATIONS -gt 10 ]]; then
    echo "⚠️  違反件数が多すぎます。閾値調整を検討してください。"
elif [[ $TOTAL_VIOLATIONS -eq 0 ]]; then
    echo "⚠️  違反件数ゼロ。検出感度が低い可能性があります。"
else
    echo "✅ 正常な範囲で動作しています。"
fi
```

## 🚨 違反検出時の対応フロー

### 即座対応（リアルタイム）

#### 1. 違反通知受信時
```
🚫 プロジェクト憲法違反が検出されました
【違反内容】大量ドキュメント作成（5ファイル同時作成）
```

**対応手順**:
1. **一時停止**: 作業を中断し違反内容を確認
2. **憲法確認**: CLAUDE.md の該当セクションを再読
3. **作業見直し**: 本当に必要な最小限に絞り込み
4. **再開**: 修正した作業内容で再実行

#### 2. 誤検出の疑い
```bash
# 緊急時の一時無効化
export CLAUDE_HOOKS_DISABLED=true

# 作業完了後、必ず再有効化
unset CLAUDE_HOOKS_DISABLED
```

### 事後分析（毎日）

#### 違反パターン調査
```bash
# 1. 違反詳細の確認
VIOLATION_ID=$(tail -1 /tmp/constitution-violations.jsonl | jq -r '.timestamp')
grep "$VIOLATION_ID" /tmp/claude-hooks.log

# 2. 前後のコンテキスト確認
grep -B 5 -A 5 "constitution_violation" /tmp/claude-hooks.log | tail -15

# 3. 根本原因分析
echo "根本原因分析チェックリスト:"
echo "□ 作業の緊急性は適切だったか？"
echo "□ 事前の計画・設計は十分だったか？"
echo "□ YAGNI原則は意識されていたか？"
echo "□ 憲法の理解は十分だったか？"
```

## 📊 統計分析・レポート

### 週次レポート生成

#### レポート項目
1. **違反検出統計**: 件数・タイプ・傾向
2. **効果測定**: 阻止されたドキュメント・計画の推定
3. **システム健全性**: Hook動作状況・パフォーマンス
4. **改善提案**: 閾値調整・新パターン追加

#### 自動レポート実行
```bash
# 毎週月曜日 9:00 に実行
# crontab -e で以下を追加:
# 0 9 * * 1 /home/kenic/projects/.claude/scripts/weekly_ai_perfectionism_report.sh
```

### 月次トレンド分析

#### 長期傾向の確認
```bash
# 月次違反件数推移
for month in {1..12}; do
    count=$(grep "2025-$(printf "%02d" $month)" /tmp/constitution-violations.jsonl 2>/dev/null | wc -l)
    echo "2025-$(printf "%02d" $month): ${count}件"
done

# 最頻出違反パターン
jq -r '.violation' /tmp/constitution-violations.jsonl 2>/dev/null | \
  sort | uniq -c | sort -nr | head -5
```

## 🔧 システム調整・最適化

### 閾値調整

#### 調整判断基準
- **違反件数 > 15件/週**: 閾値が厳しすぎる → 緩和検討
- **違反件数 = 0件/週**: 閾値が緩すぎる → 厳格化検討
- **同一違反 > 5回/日**: パターン学習・自動対応が必要

#### 設定変更手順
```bash
# 1. 現在の設定確認
grep -E "(MAX_FILES_BULK|MAX_LINES_DETAIL)" .claude/hooks/pre-tool/constitution-guard.sh

# 2. テスト環境での調整
cp .claude/hooks/pre-tool/constitution-guard.sh .claude/hooks/pre-tool/constitution-guard.sh.backup

# 3. パラメータ変更
sed -i 's/MAX_FILES_BULK=4/MAX_FILES_BULK=6/' .claude/hooks/pre-tool/constitution-guard.sh

# 4. 動作確認
.claude/scripts/test_constitution_guard.sh

# 5. 問題があればロールバック
mv .claude/hooks/pre-tool/constitution-guard.sh.backup .claude/hooks/pre-tool/constitution-guard.sh
```

### 新パターン追加

#### 検出すべき新しいパターンの特定
```bash
# 最近の違反ログから新パターンを抽出
grep "context" /tmp/constitution-violations.jsonl | \
  jq -r '.context' | sort | uniq -c | sort -nr
```

#### パターン追加手順
1. **パターン分析**: 共通する特徴を特定
2. **検出ロジック実装**: constitution-guard.sh への追加
3. **テスト**: 既知のケースでの動作確認
4. **段階的導入**: 警告モード → エラーモードの段階的強化

## 🛠️ トラブルシューティング

### よくある問題と解決策

#### 1. Hook が動作しない
**症状**: constitution-guard.sh が実行されない
```bash
# 原因調査
ls -la .claude/hooks/pre-tool/constitution-guard.sh  # 権限確認
.claude/hooks/pre-tool/constitution-guard.sh          # 手動実行テスト
grep "constitution-guard" .claude/settings.json       # 設定確認
```

**解決策**:
```bash
chmod +x .claude/hooks/pre-tool/constitution-guard.sh
# または settings.json の設定修正
```

#### 2. 誤検出が多い
**症状**: 正当な作業がブロックされる
```bash
# 最近の誤検出パターン分析
grep "false_positive" /tmp/claude-hooks.log
```

**解決策**:
- 除外対象の追加
- 閾値の緩和
- 検出ロジックの改良

#### 3. 検出漏れ
**症状**: 明らかな違反が検出されない
```bash
# 検出ロジックのテスト
echo "test content with 2027 planning" | \
  CLAUDE_TOOL_NAME="Write" CLAUDE_TOOL_ARGS='{"content":"..."}' \
  .claude/hooks/pre-tool/constitution-guard.sh
```

**解決策**:
- 検出パターンの強化
- 閾値の厳格化

### 緊急時対応

#### システム無効化
```bash
# 完全無効化（緊急時のみ）
export CLAUDE_HOOKS_DISABLED=true

# 特定Hook無効化
mv .claude/hooks/pre-tool/constitution-guard.sh \
   .claude/hooks/pre-tool/constitution-guard.sh.disabled
```

#### システム復旧
```bash
# Hook再有効化
mv .claude/hooks/pre-tool/constitution-guard.sh.disabled \
   .claude/hooks/pre-tool/constitution-guard.sh

# 設定確認
.claude/scripts/validate_constitution_guard.sh
```

## 📈 継続改善

### 月次レビュー項目
1. **効果測定**: KPI達成状況の確認
2. **パターン更新**: 新しい違反パターンの検出・追加
3. **閾値最適化**: 検出精度向上のための調整
4. **フィードバック収集**: 利用者からの改善提案

### 四半期改善計画
1. **機械学習導入**: 違反パターンの自動学習
2. **通知システム**: Slack統合・ダッシュボード構築
3. **国際化対応**: 多言語メッセージサポート
4. **API化**: 外部システムとの統合

### 年次戦略見直し
- **システム有効性評価**: ROI・効果測定の総合評価
- **技術刷新**: 新しい検出技術・AI技術の導入検討
- **拡張計画**: 他プロジェクトへの横展開

---

*この運用手順書は、AI完璧主義防止システムの効果的な日常運用と継続的改善を支援し、高品質なAI駆動開発の実現を目指します。*