// Sample Project - Main Entry Point
// Claude Code ワークスペース統合デモ

/**
 * メイン関数 - アプリケーションのエントリーポイント
 */
function main() {
    console.log('Claude Code Sample Project - TDD × YAGNI × Auto Guards');
    console.log('ワークスペース統合デモが開始されました');
    
    return {
        status: 'success',
        message: 'Demo completed',
        timestamp: new Date().toISOString()
    };
}

/**
 * 簡単な計算関数 - TDDデモ用
 * @param {number} a 
 * @param {number} b 
 * @returns {number}
 */
function add(a, b) {
    if (typeof a !== 'number' || typeof b !== 'number') {
        throw new Error('Both arguments must be numbers');
    }
    return a + b;
}

// 実行時のメイン処理
if (require.main === module) {
    main();
}

module.exports = { main, add };