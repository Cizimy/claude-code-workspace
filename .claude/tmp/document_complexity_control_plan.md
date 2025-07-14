### 1. 「プレーンテキストだけ」ではどこで破綻するか

| 兆候                  | 具体例（現在のリポジトリ）                                                       | なぜ危ないか                 |
| ------------------- | ------------------------------------------------------------------- | ---------------------- |
| **ファイル数・行数が急増**     | `implementation_verification_sop.md` が 1 200 行超、Hook スクリプトも 6 枚に分散  | 重複・リンク切れ・レビュー漏れが発生しやすい |
| **横串メタデータが手書き**     | ADR 4 本と `decision_log.md` を手動同期                                    | 人為ミスで一貫性を失いやすい         |
| **ドキュメント⇄メトリクスの往復** | 「違反ログ → SQLite ダッシュボード生成」構想が未接続                                     | 解析系が増えるほど更新漏れが起こる      |

> **目安**: 「Markdown が 100 + 枚 or 相互参照が 2 Hop 以上」で、テキストだけの運用コストが CI 時間 > 執筆時間になり始めます。

---

### 2. “全部 DB に寄せる”前に知っておきたい選択肢

| アーキテクチャ                                       | 向くケース                           | 主なメリット                              | 主なデメリット                   |
| --------------------------------------------- | ------------------------------- | ----------------------------------- | ------------------------- |
| **Docs-as-Code（Markdown＋Front-Matter＋Git）**   | *ストーリー* と *設定ファイル* を同じ repo で管理 | diff が取りやすい／Git 権限をそのまま流用           | 複雑な横断検索・集計が苦手             |
| **ハイブリッド: Markdown ＋ SQLite/DuckDB でメタデータ集約** | 決定・KPI を時系列クエリで回したい             | 既存 Markdown を壊さず SQL/CSV/HTML を自動生成 | スキーマとスクリプトの保守が必要          |
| **専用 CMS / ナレッジグラフ（Confluence、Neo4j など）**     | 非エンジニア編集者が多い、大量の再利用コンテンツ        | GUI、WYSIWYG、強力な検索／リレーション            | 権限・ホスティング・マイグレーションコストが大きい |

**実務では “ハイブリッド” が最もバランス良い**
Markdown を一次ソースに据えつつ、フロントマターや補助 YAML をクローラーで吸い上げて SQLite や GraphQL API で検索・集計をかけるケースが増えています。SQLite はファイルコピーだけでブランチ毎にスナップショットが取れるため、小規模チームでも CI に組み込みやすい ([sqlite.org][1])。

---

### 3. ベストプラクティス 7 選（段階導入モデル）

| フェーズ                    | 目的               | 具体アクション                                                                                  | 参考                                            |
| ----------------------- | ---------------- | ---------------------------------------------------------------------------------------- | --------------------------------------------- |
| **0. タイプ分け**            | “語り” と “データ” を分離 | ADR・SOP・KPI などを first-class エンティティに分類                                                    | Docs-as-Code原則 ([Kong Inc.][2])               |
| **1. Front-Matter 標準化** | 検索キーを構造化         | 全 Markdown 冒頭に `---` YAML を付与<br>例: `adr: 004`, `status: accepted`, `tags: [governance]` | GitHub Docs front-matter仕様 ([GitHub Docs][3]) |
| **2. スキーマ検証を CI に追加**   | 早期に整合性エラー検出      | `remark-lint-frontmatter-schema` で JSON Schema へ自動 lint                                  | community plugin ([Reddit][4])                |
| **3. メタデータ DB 化**       | 横断検索・ダッシュボード     | Python で front-matter を抽出 → SQLite に `INSERT`; <br>`duckdb`/`pandas` で KPI を日次集約         | SQLite 適用事例 ([paulbradley.dev][5])            |
| **4. 静的サイト生成**          | 閲覧性・全文検索         | MkDocs / Docusaurus で “人に読ませる面” を自動ビルド; Algolia などで検索                                    | —                                             |
| **5. 知識グラフ連携（任意）**      | 複雑な依存の可視化        | ADR → 決定→ Hook → KPI を Neo4j で `graph TD` 相当のクエリ                                         | —                                             |
| **6. ガバナンス自動テスト**       | ポリシー違反を即検出       | 既存 Hook と同じ CI ジョブで<br>‐ 未リンク ADR, 孤立ファイル, 重複タグ を SQL でチェック                              | —                                             |

---

### 4. 「今のレポジトリ」に合わせた移行ロードマップ案

| 週           | 作業                                                                  | 追加ファイル                          | 想定工数  |
| ----------- | ------------------------------------------------------------------- | ------------------------------- | ----- |
| **Week 1**  | *Inventory script* で Markdown 一覧＋行数＋内部リンクを CSV 出力                   | `scripts/doc_inventory.py`      | 0.5 d |
| **Week 2**  | Front-Matter 導入 & JSON Schema (`schemas/md-meta.schema.json`)       | ±0                              | 1 d   |
| **Week 3**  | GitHub Actions に `markdownlint + remark-lint frontmatter-schema` 追加 | `.github/workflows/docs-ci.yml` | 0.5 d |
| **Week 4**  | `build/docs_index.sqlite` 自動生成 + KPI HTML (既存 Step F と統合)           | `scripts/build_docs_db.py`      | 1 d   |
| **Week 5**  | MkDocs で `site/` 生成、PR にプレビュー URL                                   | `mkdocs.yml`                    | 1 d   |
| **Week 6+** | Neo4j PoC（任意）→ 成果あれば正式移行                                            | `neo4j-import/`                 | 2 d   |

> **ポイント**: 既に提案済みの *quality-gate.yaml* / SQLite ダッシュボード構想をそのまま文書メタにも適用すれば、ツールチェーンを増やさずに済みます 。

---

### 5. FAQ — よくある疑問

| 質問                           | 回答                                                                                             |
| ---------------------------- | ---------------------------------------------------------------------------------------------- |
| **DB に移したら Git の履歴が追えなくなる？** | `.md` は一次ソースのまま残し、`docs_index.sqlite` は **生成物** と割り切れば OK。履歴は Markdown 側で追える。                  |
| **将来 CMS に乗り換える可能性は？**       | ハイブリッドなら front-matter と SQLite が **中間フォーマット** になるため、Rest API で CMS へバルク移行しやすい。                 |
| **非エンジニアも編集できる？**            | MkDocs + GitHub UI で簡易編集 or GitHub Codespaces を用意。さらに必要なら Netlify CMS のような Git-backed GUI を追加。 |
| **パフォーマンスが心配**               | 数千ファイル規模でも SQLite/ DuckDB は数百ミリ秒でクエリが返る。CI で “全テスト ≤ 2 min” を切る運用例多数。                          |

---

## 結論

1. **すぐにフル DB 移行は不要**。
   *一次ソース Markdown + Front-Matter* に **構造化レイヤー（SQLite）** を噛ませるハイブリッドが最小コスト。

2. **CI でスキーマ検証・リンクテストを自動化**すれば、“破綻” の大半は防げる。
   ⇢ Docs-as-Code の定番ワークフロー ([Daily.dev][6])。

3. **横断検索・ダッシュボードが欲しくなったら**、既に計画中の SQLite KPI 基盤に “ドキュメントメタ” を同居させるだけで済む。

これらを段階的に取り入れれば、**複雑性を抑えたままドキュメントの量と深さを伸ばせる**はずです。

[1]: https://www.sqlite.org/whentouse.html?utm_source=chatgpt.com "Appropriate Uses For SQLite"
[2]: https://konghq.com/blog/learning-center/what-is-docs-as-code?utm_source=chatgpt.com "What is Docs as Code? Guide to Modern Technical Documentation"
[3]: https://docs.github.com/en/contributing/writing-for-github-docs/using-yaml-frontmatter?utm_source=chatgpt.com "Using YAML frontmatter - GitHub Docs"
[4]: https://www.reddit.com/r/Markdown/comments/wihxbl/validate_your_markdown_frontmatter_data_against_a/?utm_source=chatgpt.com "Validate your Markdown frontmatter data against a JSON schema"
[5]: https://paulbradley.dev/sqlite-generate-documentation/?utm_source=chatgpt.com "Using SQLite to generate documentation and software configurations"
[6]: https://daily.dev/blog/documentation-version-control-best-practices-2024?utm_source=chatgpt.com "Documentation Version Control: Best Practices 2024 - Daily.dev"