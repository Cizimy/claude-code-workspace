#!/bin/bash

# Claude Code Notification Sound Hook
# Plays notification sound when Claude needs user attention

# ログ関数（既存のhookパターンに合わせる）
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [sound-notifier] $1" >> /tmp/claude-hooks.log
}

log "🔔 Notification hook triggered"

# 複数の音声再生方法を試行
play_notification_sound() {
    # システムベル音を鳴らす
    if command -v speaker-test >/dev/null 2>&1; then
        log "🔊 Playing system bell sound"
        timeout 1s speaker-test -t sine -f 800 -l 1 >/dev/null 2>&1
        return 0
    fi
    
    # PulseAudioがある場合
    if command -v paplay >/dev/null 2>&1; then
        # システム音を探して再生
        for sound_file in \
            /usr/share/sounds/alsa/Front_Left.wav \
            /usr/share/sounds/ubuntu/stereo/bell.ogg \
            /usr/share/sounds/freedesktop/stereo/bell.oga \
            /System/Library/Sounds/Glass.aiff \
            /Windows/Media/Windows Notify.wav; do
            
            if [ -f "$sound_file" ]; then
                log "🔊 Playing sound file: $sound_file"
                paplay "$sound_file" 2>/dev/null
                return 0
            fi
        done
    fi
    
    # デスクトップ通知（音付き）
    if command -v notify-send >/dev/null 2>&1; then
        log "🔔 Sending desktop notification"
        notify-send "Claude Code" "アクションが完了しました" --icon=dialog-information 2>/dev/null
        return 0
    fi
    
    # ターミナルベル音（最後の手段）
    log "🔔 Playing terminal bell"
    printf '\a'
    return 0
}

# 通知音を再生
play_notification_sound

log "✅ Notification hook completed"

# 成功で終了（通知が失敗してもClaude Codeの動作を阻害しない）
exit 0