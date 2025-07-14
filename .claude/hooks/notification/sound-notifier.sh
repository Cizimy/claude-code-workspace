#!/bin/bash

# Claude Code Notification Sound Hook
# Plays notification sound when Claude needs user approval/attention

# ログ関数（既存のhookパターンに合わせる）
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [sound-notifier] $1" >> /tmp/claude-hooks.log
}

log "🔔 Notification hook triggered"

# ユーザー承認要求時のみ通知するかチェック
check_user_approval_context() {
    # Claude Codeの通知フックは以下の場合に呼ばれる：
    # 1. ユーザーの許可が必要な操作
    # 2. 60秒間のアイドル状態
    # 3. その他ユーザーの注意が必要な場合
    
    # 環境変数やコンテキストから承認要求かどうかを判定
    # (Claude Codeの通知フックは基本的にユーザー承認時なので、常に通知)
    log "📋 User attention required - proceeding with notification"
    return 0
}

# 音声のみの通知（メッセージウィンドウなし）
play_notification_sound() {
    # WSL2環境での音声通知
    if command -v wsl.exe >/dev/null 2>&1 || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        log "🔔 WSL2 environment detected - using audio notification only"
        
        # PowerShellで音声のみ（メッセージウィンドウなし）
        if command -v powershell.exe >/dev/null 2>&1; then
            log "🔊 Playing beep sound via PowerShell"
            powershell.exe -Command "[console]::beep(800,200)" 2>/dev/null
            return 0
        fi
        
        # cmd.exeでビープ音
        if command -v cmd.exe >/dev/null 2>&1; then
            log "🔔 Playing beep via cmd.exe"
            cmd.exe /c "echo ^G" 2>/dev/null
            return 0
        fi
        
        # ターミナルベル音（フォールバック）
        log "🔔 Playing terminal bell"
        printf '\a'
        return 0
    fi
    
    # Linux ネイティブ環境
    if command -v paplay >/dev/null 2>&1; then
        for sound_file in \
            /usr/share/sounds/alsa/Front_Left.wav \
            /usr/share/sounds/ubuntu/stereo/bell.ogg \
            /usr/share/sounds/freedesktop/stereo/bell.oga; do
            
            if [ -f "$sound_file" ]; then
                log "🔊 Playing sound file: $sound_file"
                paplay "$sound_file" 2>/dev/null
                return 0
            fi
        done
    fi
    
    # ターミナルベル音
    log "🔔 Playing terminal bell"
    printf '\a'
    return 0
}

# ユーザー承認コンテキストをチェックしてから通知
if check_user_approval_context; then
    # 通知音を再生
    play_notification_sound
    log "✅ Notification sound played - user attention required"
else
    log "ℹ️  Notification skipped - not an approval context"
fi

log "✅ Notification hook completed"

# 成功で終了（通知が失敗してもClaude Codeの動作を阻害しない）
exit 0