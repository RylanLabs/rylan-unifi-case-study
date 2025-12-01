#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
am start -n com.beemdevelopment.aegis/.MainActivity
termux-notification --title "TOTP Beacon Alive" --content "10.0.30.45"
