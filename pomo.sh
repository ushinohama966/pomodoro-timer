#!/bin/bash

clear

trap 'printf "\033[?25h\033[0m"; exit 1' 2
trap 'printf "\033[?25h\033[0m";' EXIT
trap '
    if [ -n "$PLAYER_PID" ]; then
        kill "$PLAYER_PID" 2>/dev/null
    fi
    printf "\033[?25h\033[0m"
' EXIT

# ターミナル上のフォーカスを消す
printf "\033[?25l"

work_time=$((25 * 60))

rest_time=$((5 * 60))

big_rest_time=$((20 * 60))

big_rest_interval=4

print_center() {
    line_offset=$1
    content=$2
    base_width=36

    y=$(( ($LINES / 2) + $line_offset ))
    x=$(( ($COLUMNS - $base_width) / 2 ))

    printf "\033[%d;%dH%b\033[K" "$y" "$x" "$content"
}

stdout_time() {
    if [ $1 -le 0 ]; then
        return
    fi

    min=$(( $1 / 60 ))
    sec=$(( $1 % 60 ))
    text_str=$(printf "\033[1;32m[ TIME   ]\033[0m %02d:%02d  [q:終了]" "$min" "$sec")
    print_center 1 "$text_str"
    if read -t 1 -n 1 -s key 2>/dev/null; then
        if [ "$key" = "q" ]; then
            exit 0
        fi
    fi
    stdout_time $(($1 - 1))
}

count=1

while true; do
  print_center -1 "\033[1;32m--- 第${count}セッション開始 ($(date +%H:%M)) ---\033[0m"

  print_center 0 "\033[1;36m[ STATUS ]\033[0m 作業中..."
  stdout_time $work_time

  notify-send "作業終了！" "第${count}セッションが完了しました。休憩してください" 2>/dev/null &
  ffplay -nodisp -autoexit -loglevel quiet notification.mp3 & PLAYER_PID=$!

  if (($count % $big_rest_interval == 0)); then
    print_center 0 "\033[1;36m[ STATUS ]\033[0m 大休憩中..."
    stdout_time $big_rest_time
  else
    print_center 0 "\033[1;36m[ STATUS ]\033[0m 休憩中..."
    stdout_time $rest_time
  fi

  notify-send "休憩終了" "次のセッションを開始します" 2>/dev/null &
  ffplay -nodisp -autoexit -loglevel quiet notification.mp3 & PLAYER_PID=$!

  count=$((count + 1))
done
