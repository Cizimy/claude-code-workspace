#!/usr/bin/env python3
"""
ドキュメント棚卸スクリプト (Week 1 実装)
ADR-005 ドキュメント複雑性制御システムの第一段階

目的: 全Markdownファイルの現状分析・複雑性測定
出力: CSV形式での一覧・行数・内部リンク・複雑性ホットスポット
"""

import os
import re
import csv
import sys
import json
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple, Optional

class DocumentInventory:
    """ドキュメント複雑性分析・棚卸システム"""
    
    def __init__(self, root_path: str = "."):
        self.root_path = Path(root_path)
        self.skip_patterns = [
            'node_modules/', '.git/', '__pycache__/', 'build/', 
            '.claude/tmp/', 'venv/', '.venv/', 'dist/'
        ]
        self.results = []
        
    def should_skip(self, file_path: Path) -> bool:
        """処理除外判定"""
        file_str = str(file_path)
        return any(pattern in file_str for pattern in self.skip_patterns)
        
    def extract_frontmatter_simple(self, content: str) -> Optional[Dict]:
        """簡易Front-Matter抽出"""
        if not content.startswith('---\n'):
            return None
            
        try:
            parts = content.split('---\n', 2)
            if len(parts) < 3:
                return None
                
            # YAML簡易パース（yamlライブラリなしでの基本解析）
            yaml_content = parts[1]
            frontmatter = {}
            
            for line in yaml_content.strip().split('\n'):
                if ':' in line:
                    key, value = line.split(':', 1)
                    key = key.strip()
                    value = value.strip().strip('"\'')
                    frontmatter[key] = value
                    
            return frontmatter
        except Exception:
            return None
            
    def analyze_content(self, content: str) -> Dict:
        """コンテンツ詳細解析"""
        lines = content.splitlines()
        
        # リンク解析
        internal_links = re.findall(r'\[.*?\]\([^)]*\.md[^)]*\)', content)
        external_links = re.findall(r'\[.*?\]\(https?://[^)]+\)', content)
        
        # ヘッダー解析
        headers = re.findall(r'^#+\s+.*$', content, re.MULTILINE)
        
        # コードブロック解析
        code_blocks = re.findall(r'```[\s\S]*?```', content)
        
        # テーブル解析
        tables = re.findall(r'\|.*\|', content)
        
        return {
            'lines': len(lines),
            'words': len(content.split()),
            'chars': len(content),
            'internal_links': len(internal_links),
            'external_links': len(external_links),
            'headers': len(headers),
            'code_blocks': len(code_blocks),
            'tables': len(tables),
            'internal_link_list': internal_links[:5],  # 最初の5個のリンク
            'avg_line_length': sum(len(line) for line in lines) / len(lines) if lines else 0
        }
        
    def calculate_complexity_score(self, analysis: Dict) -> float:
        """複雑性スコア計算"""
        # 複雑性算出式
        # - 行数: 1行あたり0.1ポイント
        # - 内部リンク: 1リンクあたり2ポイント
        # - ヘッダー: 1ヘッダーあたり0.5ポイント（構造化度）
        # - 長い行: 100文字超で追加ペナルティ
        
        base_score = analysis['lines'] * 0.1
        link_score = analysis['internal_links'] * 2.0
        header_score = analysis['headers'] * 0.5
        
        # 長い行のペナルティ
        long_line_penalty = max(0, analysis['avg_line_length'] - 100) * 0.01
        
        total_score = base_score + link_score + header_score + long_line_penalty
        return round(total_score, 2)
        
    def categorize_complexity(self, score: float) -> Tuple[str, str]:
        """複雑性レベル分類"""
        if score < 50:
            return "Low", "🟢"
        elif score < 100:
            return "Medium", "🟡"
        elif score < 200:
            return "High", "🟠"
        else:
            return "Critical", "🔴"
            
    def analyze_file(self, file_path: Path) -> Dict:
        """単一ファイル分析"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # 基本情報
            stat = file_path.stat()
            relative_path = file_path.relative_to(self.root_path)
            
            # Front-Matter解析
            frontmatter = self.extract_frontmatter_simple(content)
            
            # コンテンツ解析
            analysis = self.analyze_content(content)
            
            # 複雑性スコア
            complexity_score = self.calculate_complexity_score(analysis)
            complexity_level, complexity_icon = self.categorize_complexity(complexity_score)
            
            result = {
                # ファイル情報
                'file_path': str(relative_path),
                'file_name': file_path.name,
                'directory': str(relative_path.parent),
                'size_bytes': stat.st_size,
                'modified_time': datetime.fromtimestamp(stat.st_mtime).isoformat(),
                
                # Front-Matter情報
                'has_frontmatter': frontmatter is not None,
                'title': frontmatter.get('title', '') if frontmatter else '',
                'status': frontmatter.get('status', '') if frontmatter else '',
                'category': frontmatter.get('category', '') if frontmatter else '',
                'tags': frontmatter.get('tags', '') if frontmatter else '',
                
                # コンテンツ解析
                'lines': analysis['lines'],
                'words': analysis['words'],
                'chars': analysis['chars'],
                'internal_links': analysis['internal_links'],
                'external_links': analysis['external_links'],
                'headers': analysis['headers'],
                'code_blocks': analysis['code_blocks'],
                'tables': analysis['tables'],
                'avg_line_length': round(analysis['avg_line_length'], 1),
                
                # 複雑性評価
                'complexity_score': complexity_score,
                'complexity_level': complexity_level,
                'complexity_icon': complexity_icon,
                
                # 問題検出
                'issues': self.detect_issues(analysis, frontmatter),
                'sample_internal_links': ', '.join(analysis['internal_link_list'])
            }
            
            return result
            
        except Exception as e:
            return {
                'file_path': str(relative_path),
                'error': str(e),
                'complexity_level': 'Error',
                'complexity_icon': '❌'
            }
            
    def detect_issues(self, analysis: Dict, frontmatter: Optional[Dict]) -> List[str]:
        """問題・改善点検出"""
        issues = []
        
        # ADR-005基準チェック
        if analysis['lines'] > 500:
            issues.append('LINE_LIMIT_EXCEEDED')
            
        if analysis['internal_links'] > 10:
            issues.append('LINK_LIMIT_EXCEEDED')
            
        if not frontmatter:
            issues.append('MISSING_FRONTMATTER')
        else:
            required_fields = ['title', 'status', 'category']
            for field in required_fields:
                if not frontmatter.get(field):
                    issues.append(f'MISSING_{field.upper()}')
                    
        # その他の品質問題
        if analysis['avg_line_length'] > 120:
            issues.append('LONG_LINES')
            
        if analysis['headers'] == 0 and analysis['lines'] > 50:
            issues.append('NO_STRUCTURE')
            
        if analysis['internal_links'] == 0 and analysis['lines'] > 100:
            issues.append('ISOLATED_DOCUMENT')
            
        return issues
        
    def scan_all_files(self) -> List[Dict]:
        """全Markdownファイルスキャン"""
        print(f"📁 Scanning markdown files in: {self.root_path}")
        
        markdown_files = list(self.root_path.rglob('*.md'))
        markdown_files = [f for f in markdown_files if not self.should_skip(f)]
        
        print(f"📄 Found {len(markdown_files)} markdown files")
        
        results = []
        for i, file_path in enumerate(markdown_files, 1):
            print(f"🔍 Analyzing ({i}/{len(markdown_files)}): {file_path.name}")
            result = self.analyze_file(file_path)
            results.append(result)
            
        self.results = results
        return results
        
    def generate_summary(self) -> Dict:
        """分析結果サマリ生成"""
        if not self.results:
            return {}
            
        valid_results = [r for r in self.results if 'error' not in r]
        
        summary = {
            'scan_date': datetime.now().isoformat(),
            'total_files': len(self.results),
            'valid_files': len(valid_results),
            'error_files': len(self.results) - len(valid_results),
            
            # 基本統計
            'total_lines': sum(r.get('lines', 0) for r in valid_results),
            'total_words': sum(r.get('words', 0) for r in valid_results),
            'avg_lines_per_file': round(sum(r.get('lines', 0) for r in valid_results) / max(len(valid_results), 1), 1),
            'avg_complexity_score': round(sum(r.get('complexity_score', 0) for r in valid_results) / max(len(valid_results), 1), 2),
            
            # Front-Matter統計
            'frontmatter_coverage': round(sum(1 for r in valid_results if r.get('has_frontmatter', False)) / max(len(valid_results), 1) * 100, 1),
            
            # 複雑性分布
            'complexity_distribution': self.get_complexity_distribution(valid_results),
            
            # 問題統計
            'common_issues': self.get_issue_statistics(valid_results),
            
            # ホットスポット
            'complexity_hotspots': self.get_hotspots(valid_results),
            
            # カテゴリ別統計
            'category_stats': self.get_category_statistics(valid_results)
        }
        
        return summary
        
    def get_complexity_distribution(self, results: List[Dict]) -> Dict:
        """複雑性レベル分布"""
        distribution = {'Low': 0, 'Medium': 0, 'High': 0, 'Critical': 0}
        for result in results:
            level = result.get('complexity_level', 'Unknown')
            if level in distribution:
                distribution[level] += 1
        return distribution
        
    def get_issue_statistics(self, results: List[Dict]) -> Dict:
        """問題統計"""
        issue_counts = {}
        for result in results:
            for issue in result.get('issues', []):
                issue_counts[issue] = issue_counts.get(issue, 0) + 1
        
        # 上位5問題を返す
        sorted_issues = sorted(issue_counts.items(), key=lambda x: x[1], reverse=True)
        return dict(sorted_issues[:5])
        
    def get_hotspots(self, results: List[Dict], limit: int = 10) -> List[Dict]:
        """複雑性ホットスポット"""
        sorted_results = sorted(results, key=lambda x: x.get('complexity_score', 0), reverse=True)
        
        hotspots = []
        for result in sorted_results[:limit]:
            hotspots.append({
                'file': result.get('file_path', ''),
                'complexity_score': result.get('complexity_score', 0),
                'complexity_level': result.get('complexity_level', ''),
                'lines': result.get('lines', 0),
                'internal_links': result.get('internal_links', 0),
                'main_issues': result.get('issues', [])[:3]  # 上位3問題
            })
            
        return hotspots
        
    def get_category_statistics(self, results: List[Dict]) -> Dict:
        """カテゴリ別統計"""
        category_stats = {}
        
        for result in results:
            category = result.get('category', 'uncategorized')
            if category not in category_stats:
                category_stats[category] = {
                    'count': 0,
                    'total_lines': 0,
                    'avg_complexity': 0,
                    'frontmatter_rate': 0
                }
                
            stats = category_stats[category]
            stats['count'] += 1
            stats['total_lines'] += result.get('lines', 0)
            
        # 平均値計算
        for category, stats in category_stats.items():
            if stats['count'] > 0:
                category_results = [r for r in results if r.get('category', 'uncategorized') == category]
                stats['avg_lines'] = round(stats['total_lines'] / stats['count'], 1)
                stats['avg_complexity'] = round(sum(r.get('complexity_score', 0) for r in category_results) / stats['count'], 2)
                stats['frontmatter_rate'] = round(sum(1 for r in category_results if r.get('has_frontmatter', False)) / stats['count'] * 100, 1)
                
        return category_stats
        
    def export_csv(self, filename: str = 'doc_inventory.csv'):
        """CSV出力"""
        if not self.results:
            print("❌ No results to export")
            return
            
        fieldnames = [
            'file_path', 'file_name', 'directory', 'lines', 'words', 
            'internal_links', 'external_links', 'complexity_score', 
            'complexity_level', 'has_frontmatter', 'title', 'status', 
            'category', 'issues', 'modified_time'
        ]
        
        with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames, extrasaction='ignore')
            writer.writeheader()
            
            for result in self.results:
                # issues をカンマ区切り文字列に変換
                result_copy = result.copy()
                result_copy['issues'] = ', '.join(result.get('issues', []))
                writer.writerow(result_copy)
                
        print(f"📊 CSV exported: {filename}")
        
    def export_json(self, filename: str = 'doc_inventory.json'):
        """JSON出力（詳細情報）"""
        if not self.results:
            print("❌ No results to export")
            return
            
        export_data = {
            'metadata': {
                'scan_date': datetime.now().isoformat(),
                'tool': 'doc_inventory.py',
                'version': '1.0',
                'adr': 'ADR-005'
            },
            'summary': self.generate_summary(),
            'files': self.results
        }
        
        with open(filename, 'w', encoding='utf-8') as jsonfile:
            json.dump(export_data, jsonfile, indent=2, ensure_ascii=False)
            
        print(f"📋 JSON exported: {filename}")
        
    def print_summary_report(self):
        """サマリレポート表示"""
        summary = self.generate_summary()
        
        print("\n" + "="*60)
        print("📊 DOCUMENT COMPLEXITY ANALYSIS REPORT")
        print("="*60)
        print(f"📅 Scan Date: {summary['scan_date']}")
        print(f"📁 Total Files: {summary['total_files']}")
        print(f"✅ Valid Files: {summary['valid_files']}")
        if summary['error_files'] > 0:
            print(f"❌ Error Files: {summary['error_files']}")
            
        print(f"\n📈 BASIC STATISTICS")
        print(f"├─ Total Lines: {summary['total_lines']:,}")
        print(f"├─ Total Words: {summary['total_words']:,}")
        print(f"├─ Avg Lines/File: {summary['avg_lines_per_file']}")
        print(f"└─ Avg Complexity: {summary['avg_complexity_score']}")
        
        print(f"\n🏷️ FRONT-MATTER COVERAGE")
        print(f"└─ Coverage Rate: {summary['frontmatter_coverage']}%")
        
        print(f"\n🎯 COMPLEXITY DISTRIBUTION")
        for level, count in summary['complexity_distribution'].items():
            icon = {'Low': '🟢', 'Medium': '🟡', 'High': '🟠', 'Critical': '🔴'}.get(level, '⚪')
            print(f"├─ {icon} {level}: {count} files")
            
        print(f"\n⚠️ COMMON ISSUES")
        for issue, count in summary['common_issues'].items():
            print(f"├─ {issue}: {count} files")
            
        print(f"\n🔴 COMPLEXITY HOTSPOTS (Top 5)")
        for i, hotspot in enumerate(summary['complexity_hotspots'][:5], 1):
            print(f"{i}. {hotspot['file']} (Score: {hotspot['complexity_score']}, {hotspot['lines']} lines)")
            
        print(f"\n📊 CATEGORY BREAKDOWN")
        for category, stats in summary['category_stats'].items():
            print(f"├─ {category}: {stats['count']} files, {stats['avg_lines']} avg lines")
            
        print("\n" + "="*60)
        
def main():
    parser = argparse.ArgumentParser(description='Document Complexity Analysis (ADR-005)')
    parser.add_argument('--path', default='.', help='Root path to scan (default: current directory)')
    parser.add_argument('--output', default='doc_inventory', help='Output filename prefix')
    parser.add_argument('--format', choices=['csv', 'json', 'both'], default='both', help='Output format')
    parser.add_argument('--quiet', action='store_true', help='Quiet mode (no summary report)')
    parser.add_argument('--ci-mode', action='store_true', help='CI mode (exit code 1 if critical issues found)')
    parser.add_argument('--baseline', action='store_true', help='Generate baseline for comparison')
    
    args = parser.parse_args()
    
    # インベントリ実行
    inventory = DocumentInventory(args.path)
    results = inventory.scan_all_files()
    
    if not results:
        print("❌ No markdown files found")
        sys.exit(1)
        
    # 出力
    if args.format in ['csv', 'both']:
        inventory.export_csv(f"{args.output}.csv")
        
    if args.format in ['json', 'both']:
        inventory.export_json(f"{args.output}.json")
        
    # サマリレポート
    if not args.quiet:
        inventory.print_summary_report()
        
    # CI モード: 重大な問題がある場合は exit code 1
    if args.ci_mode:
        summary = inventory.generate_summary()
        critical_issues = summary['complexity_distribution'].get('Critical', 0)
        missing_frontmatter = summary['common_issues'].get('MISSING_FRONTMATTER', 0)
        
        if critical_issues > 0:
            print(f"\n💥 CI ERROR: {critical_issues} files with Critical complexity")
            sys.exit(1)
            
        if missing_frontmatter > 5:  # 5ファイル以上でFront-Matter未設定
            print(f"\n💥 CI ERROR: {missing_frontmatter} files missing Front-Matter")
            sys.exit(1)
            
    print(f"\n✅ Analysis complete. See {args.output}.csv and {args.output}.json for details.")

if __name__ == "__main__":
    main()