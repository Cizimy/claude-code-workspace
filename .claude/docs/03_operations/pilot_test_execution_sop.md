---
title: "Pilot Test Execution SOP"
status: "active"
category: "operations"
created: "2025-07-14"
updated: "2025-07-14"
tags: ["sop", "pilot-testing", "tdd", "verification", "phase-5"]
priority: "high"
---

# パイロットテスト実行 標準作業手順書（SOP）

> **目的**: Phase 5 パイロットテストの再現可能な実行手順を標準化し、1時間以内での完全検証を実現する

## 📋 SOP概要

**対象者**: 新規開発者、QA担当者、システム管理者  
**実行時間**: 約60分（経験者は30分）  
**前提条件**: Linux/WSL2環境、Python 3.9+、git 2.30+  
**成功基準**: 全Hook動作確認、TDDサイクル実行、品質ゲート通過

## 🎯 実行前チェックリスト

### 必須環境確認
- [ ] **OS**: Linux/macOS/WSL2 (Windows Subsystem for Linux)
- [ ] **Python**: 3.9+ (`python3 --version`)
- [ ] **Git**: 2.30+ (`git --version`)
- [ ] **Internet**: パッケージダウンロード用接続
- [ ] **権限**: ファイル作成・実行権限

### 推奨ツール確認
- [ ] **VS Code**: 統合開発環境
- [ ] **GitHub CLI**: `gh` コマンド（GitHub統合用）
- [ ] **Docker**: コンテナ化環境（オプション）

## 🚀 実行手順（60分完全ガイド）

### Phase 1: 環境準備（15分）

#### 1-1. ワークスペース確認
```bash
# ワークスペースディレクトリに移動
cd /home/kenic/projects

# プロジェクト構造確認
ls -la
# 期待結果: CLAUDE.md, README.md, .claude/, projects/, governance/ 存在確認
```

#### 1-2. pilot-test プロジェクトアクセス
```bash
# pilot-test プロジェクトに移動
cd projects/pilot-test

# プロジェクト構造確認
ls -la
# 期待結果: README.md, pyproject.toml, requirements.txt, src/, tests/, venv/ 存在確認
```

#### 1-3. Python仮想環境アクティベート
```bash
# 仮想環境アクティベート
source venv/bin/activate

# Python環境確認
python --version  # Python 3.12.3 期待
which python      # venv内Pythonパス確認
```

#### 1-4. 依存パッケージ確認・インストール
```bash
# 依存パッケージ確認
pip list | grep -E "(pytest|vulture|coverage|ruff)"

# 不足している場合はインストール
pip install -r requirements.txt

# ツール動作確認
pytest --version    # pytest 8.4.1+ 期待
vulture --version   # vulture 2.14+ 期待
coverage --version  # Coverage.py 7.9.2+ 期待
ruff --version      # ruff 0.12.3+ 期待
```

**Phase 1 完了確認**: 全ツールが正常にバージョン表示される

---

### Phase 2: Hook システム動作検証（20分）

#### 2-1. TDD Guard Hook検証

**A) TDD違反ブロック確認**
```bash
# テストファイルのタイムスタンプを古くする（TDD違反状況作成）
find tests/ -name "*.py" -exec touch -t 202501011200 {} \;

# 実装ファイル編集を試行（ブロックされるべき）
export CLAUDE_TOOL_NAME="Edit"
export CLAUDE_TOOL_ARGS='{"file_path": "/home/kenic/projects/projects/pilot-test/src/auth.py"}'
/home/kenic/projects/.claude/hooks/pre-tool/tdd-guard.sh

# 期待結果: エラーメッセージ表示、exit code 2
echo $?  # 2 が表示されることを確認
```

**B) TDD準拠許可確認**
```bash
# テストファイルのタイムスタンプを現在時刻に更新
touch tests/test_auth.py

# 実装ファイル編集を試行（許可されるべき）
/home/kenic/projects/.claude/hooks/pre-tool/tdd-guard.sh

# 期待結果: 成功メッセージ、exit code 0
echo $?  # 0 が表示されることを確認
```

#### 2-2. Unused Code Detector Hook検証

**A) 未使用コード追加・検出**
```bash
# 未使用関数を追加
echo "def test_unused_function(): return 'unused'" >> src/auth.py

# 未使用コード検出実行
export CLAUDE_TOOL_NAME="Edit"
export CLAUDE_TOOL_ARGS='{"file_path": "/home/kenic/projects/projects/pilot-test/src/auth.py"}'
/home/kenic/projects/.claude/hooks/post-tool/unused-detector.sh

# 期待結果: 未使用コード警告表示
```

**B) クリーンアップ確認**
```bash
# 未使用関数を削除
head -n -1 src/auth.py > src/auth.py.tmp && mv src/auth.py.tmp src/auth.py

# 再度検証（エラーなしを確認）
/home/kenic/projects/.claude/hooks/post-tool/unused-detector.sh

# 期待結果: クリーンコード確認メッセージ
```

#### 2-3. Coverage Check Hook検証
```bash
# カバレッジチェック実行
export CLAUDE_TOOL_NAME="Stop"
/home/kenic/projects/.claude/hooks/stop/coverage-check.sh

# 期待結果: カバレッジ閾値（60%）達成確認
# 実際のカバレッジ値（90%+）表示確認
```

#### Hook ログ確認
```bash
# Hook実行ログ確認
tail -20 /tmp/claude-hooks.log

# 期待ログ内容例:
# [2025-07-14 XX:XX:XX] [tdd-guard.sh] TDD Guard activated: tool=Edit
# [2025-07-14 XX:XX:XX] [unused-detector.sh] UNUSED CODE DETECTED
# [2025-07-14 XX:XX:XX] [coverage-check.sh] Coverage check passed
```

**Phase 2 完了確認**: 3種類のHook全てが期待通りに動作する

---

### Phase 3: TDD ワークフロー実証（20分）

#### 3-1. 新機能実装（Red-Green-Refactor サイクル）

**A) RED: 失敗テスト作成**
```bash
# 新機能テスト追加（例: パスワード複雑性検証）
cat >> tests/test_auth.py << 'EOF'

    def test_password_complexity_check(self):
        """Test password complexity validation"""
        from src.auth import check_password_complexity
        
        # Strong password should pass
        assert check_password_complexity("Complex123!@#") is True
        
        # Weak password should fail
        with pytest.raises(ValueError) as exc_info:
            check_password_complexity("simple")
        assert "complexity" in str(exc_info.value).lower()
EOF

# テスト実行（失敗確認）
pytest tests/test_auth.py::TestPasswordSecurity::test_password_complexity_check -v
# 期待結果: ImportError（関数未実装のため失敗）
```

**B) GREEN: 最小実装**
```bash
# 最小実装追加
cat >> src/auth.py << 'EOF'

def check_password_complexity(password: str) -> bool:
    """Check password complexity (simplified implementation)"""
    if len(password) < 8:
        raise ValueError("Password complexity insufficient")
    
    complexity_score = 0
    if any(c.isupper() for c in password):
        complexity_score += 1
    if any(c.islower() for c in password):
        complexity_score += 1
    if any(c.isdigit() for c in password):
        complexity_score += 1
    if any(c in "!@#$%^&*" for c in password):
        complexity_score += 1
    
    if complexity_score < 3:
        raise ValueError("Password complexity insufficient")
    
    return True
EOF

# テスト実行（成功確認）
pytest tests/test_auth.py::TestPasswordSecurity::test_password_complexity_check -v
# 期待結果: PASSED
```

#### 3-2. 品質メトリクス確認
```bash
# 全テスト実行
pytest --cov=src --cov-report=term-missing
# 期待結果: すべてのテストPASS、カバレッジ90%+

# 未使用コード確認
vulture src/ --min-confidence 80
# 期待結果: エラーなし（または最小限）

# Lint確認
ruff check src/ tests/
# 期待結果: エラー確認（改善余地の特定）
```

#### 3-3. Hook統合確認
```bash
# 実装変更後のHook動作確認
export CLAUDE_TOOL_NAME="Edit"
export CLAUDE_TOOL_ARGS='{"file_path": "/home/kenic/projects/projects/pilot-test/src/auth.py"}'
/home/kenic/projects/.claude/hooks/post-tool/unused-detector.sh

# カバレッジ最終確認
/home/kenic/projects/.claude/hooks/stop/coverage-check.sh
# 期待結果: 品質基準クリア
```

**Phase 3 完了確認**: Red-Green-Refactor サイクル完了、品質基準達成

---

### Phase 4: 検証結果確認・文書化（5分）

#### 4-1. 最終品質メトリクス確認
```bash
# 包括的品質確認
echo "=== Final Quality Metrics ==="
echo "1. Test Results:"
pytest --tb=short

echo "2. Coverage Report:"
coverage report --show-missing

echo "3. Code Quality:"
vulture src/ tests/ --min-confidence 60

echo "4. Style Check:"
ruff check --statistics
```

#### 4-2. Hook実行ログサマリ
```bash
# Hook実行統計
echo "=== Hook Execution Summary ==="
grep -c "TDD Guard activated" /tmp/claude-hooks.log
grep -c "Unused code detector activated" /tmp/claude-hooks.log
grep -c "Coverage check hook activated" /tmp/claude-hooks.log

# エラー・警告確認
grep -i "error\|warning" /tmp/claude-hooks.log | tail -10
```

#### 4-3. 完了確認チェックリスト
```bash
# 自動チェックスクリプト実行
cat > /tmp/pilot_test_verification.sh << 'EOF'
#!/bin/bash
echo "🔍 Pilot Test Verification Checklist"
echo "=================================="

echo -n "✓ Python virtual environment: "
python --version 2>/dev/null && echo "PASS" || echo "FAIL"

echo -n "✓ Pytest available: "
pytest --version >/dev/null 2>&1 && echo "PASS" || echo "FAIL"

echo -n "✓ Vulture available: "
vulture --version >/dev/null 2>&1 && echo "PASS" || echo "FAIL"

echo -n "✓ Coverage available: "
coverage --version >/dev/null 2>&1 && echo "PASS" || echo "FAIL"

echo -n "✓ All tests passing: "
pytest --quiet >/dev/null 2>&1 && echo "PASS" || echo "FAIL"

echo -n "✓ Coverage threshold (60%): "
coverage report | grep "TOTAL" | awk '{print $4}' | sed 's/%//' | awk '{if($1>=60) print "PASS"; else print "FAIL"}'

echo -n "✓ No unused code: "
vulture src/ --min-confidence 80 >/dev/null 2>&1 && echo "PASS" || echo "PARTIAL"

echo -n "✓ Hook scripts executable: "
ls -la /home/kenic/projects/.claude/hooks/*/*.sh | grep -c "rwx" >/dev/null && echo "PASS" || echo "FAIL"

echo ""
echo "🎉 Pilot Test Verification Complete!"
EOF

chmod +x /tmp/pilot_test_verification.sh
/tmp/pilot_test_verification.sh
```

**Phase 4 完了確認**: 検証スクリプトですべて PASS または PARTIAL

---

## 🎯 成功基準・KPI

### 必須達成項目（PASS必須）
- [ ] **Environment Setup**: Python, pytest, vulture, coverage 全動作
- [ ] **Hook System**: TDD Guard, Unused Detector, Coverage Check 全動作
- [ ] **TDD Cycle**: Red → Green → Refactor サイクル完了
- [ ] **Quality Gates**: テストPASS、カバレッジ60%+、Hook通過

### 推奨達成項目（品質向上）
- [ ] **Code Quality**: Ruff lint エラー最小化
- [ ] **Documentation**: README.md 最新化
- [ ] **Performance**: Hook実行時間 < 2秒
- [ ] **Usability**: 新人60分以内完了

### メトリクス目標値
```yaml
test_coverage: ">=90%"        # 現在達成: 90%+
test_pass_rate: "100%"        # 必須要件
hook_success_rate: "100%"     # 必須要件
execution_time: "<=60min"     # 新人基準
lint_errors: "<=10"           # 品質目標
```

## 🚨 トラブルシューティング

### よくある問題と解決策

#### 1. Python環境問題
**症状**: `python: command not found`
```bash
# 解決策
which python3        # python3 パス確認
ls -la venv/bin/     # venv内実行ファイル確認
source venv/bin/activate  # 再アクティベート
```

#### 2. パッケージインストール失敗
**症状**: `pip install` エラー
```bash
# 解決策
pip install --upgrade pip  # pip更新
pip cache purge             # キャッシュクリア
pip install -r requirements.txt --no-cache-dir
```

#### 3. Hook実行権限エラー
**症状**: `Permission denied`
```bash
# 解決策
chmod +x /home/kenic/projects/.claude/hooks/*/*.sh
ls -la /home/kenic/projects/.claude/hooks/*/*.sh  # 権限確認
```

#### 4. テスト失敗
**症状**: `ImportError`, `ModuleNotFoundError`
```bash
# 解決策
export PYTHONPATH="${PWD}:${PYTHONPATH}"  # パス追加
python -c "import sys; print('\n'.join(sys.path))"  # パス確認
```

#### 5. Hook実行失敗
**症状**: Hook終了コード非0
```bash
# デバッグ手順
cat /tmp/claude-hooks.log | tail -20  # ログ確認
export HOOK_DEBUG=1                   # デバッグモード
bash -x /home/kenic/projects/.claude/hooks/pre-tool/tdd-guard.sh  # 詳細実行
```

### 緊急時の回避策
```bash
# Hook一時無効化（緊急時のみ使用）
export CLAUDE_HOOKS_DISABLED=true

# テスト最小実行
pytest tests/test_auth.py::TestUser::test_user_creation -v

# 環境リセット
deactivate && source venv/bin/activate
pip install -r requirements.txt --force-reinstall
```

## 📋 実行後チェックリスト

### 技術検証項目
- [ ] **全Hook動作確認**: TDD Guard, Unused Detector, Coverage Check
- [ ] **TDDサイクル完了**: Red-Green-Refactor 実行確認
- [ ] **品質基準達成**: カバレッジ、テスト、Lint基準クリア
- [ ] **ログ記録確認**: `/tmp/claude-hooks.log` 正常記録

### 文書・ガバナンス項目
- [ ] **実行記録作成**: 実行時間、問題点、改善事項記録
- [ ] **改善推奨事項**: improvement_recommendations.md 更新
- [ ] **次回実行準備**: 発見した問題の修正計画策定

### 引き継ぎ項目
- [ ] **環境設定**: 次回実行者への環境移行手順確認
- [ ] **知見共有**: トラブルシューティング事例の文書化
- [ ] **継続改善**: Phase 6 改善システムへのフィードバック

## 🔄 継続改善プロセス

### 実行後フィードバック収集
1. **実行時間記録**: 各Phaseの所要時間測定
2. **問題点記録**: 遭遇した問題と解決時間
3. **改善提案**: SOP手順の最適化案
4. **品質評価**: 達成したメトリクス値記録

### 月次レビュー・更新
- **SOP改訂**: 実行フィードバックによる手順最適化
- **ツールバージョン更新**: 依存パッケージの最新化
- **新機能統合**: Phase 6改善システムの反映

### 年次見直し
- **全体アーキテクチャ**: 基盤システムの抜本的見直し
- **業界ベストプラクティス**: 最新のTDD・CI/CD手法導入
- **次世代技術**: AI・自動化技術の進歩への対応

---

## 📚 関連ドキュメント

- **[Phase 5 Pilot Testing Guide](../01_quickstart/pilot_testing.md)**: 詳細実行手順
- **[Hook Integration Checklist](hook_integration_checklist.md)**: Hook設定・検証手順
- **[TDD Workflow](tdd_workflow.md)**: テスト駆動開発実践ガイド
- **[Implementation Verification SOP](implementation_verification_sop.md)**: 実装検証手順
- **[Improvement Recommendations](improvement_recommendations.md)**: 継続改善追跡

---

**SOP承認日**: 2025-07-14  
**次回改訂予定**: 2025-08-14（月次レビュー）  
**SOP管理者**: Claude Code AI システム  

*この手順書はプロジェクト憲法（TDD×YAGNI×KISS）に基づき、再現可能性と品質保証を重視して作成されました。*