#!/bin/bash
# Мониторинг состояния наушников и переключение аудиовыходов Huawei

set -e

function move_output() {
   hda-verb /dev/snd/hwC0D0 0x16 0x701 "$@" >/dev/null 2>/dev/null
}

function move_output_to_speaker() {
    move_output 0x0001
}

function move_output_to_headphones() {
    move_output 0x0000
}

function switch_to_speaker() {
    move_output_to_speaker
    hda-verb /dev/snd/hwC0D0 0x17 0x70C 0x0002 >/dev/null 2>/dev/null
    hda-verb /dev/snd/hwC0D0 0x1 0x715 0x2 >/dev/null 2>/dev/null
}

function switch_to_headphones() {
    move_output_to_headphones
    hda-verb /dev/snd/hwC0D0 0x17 0x70C 0x0000 >/dev/null 2>/dev/null
    hda-verb /dev/snd/hwC0D0 0x1 0x717 0x2 >/dev/null 2>/dev/null
    hda-verb /dev/snd/hwC0D0 0x1 0x716 0x2 >/dev/null 2>/dev/null
    hda-verb /dev/snd/hwC0D0 0x1 0x715 0x0 >/dev/null 2>/dev/null
}

function get_sound_card_index() {
    card_index=$(cat /proc/asound/cards | grep sof-hda-dsp | head -n1 | grep -Eo "^\s*[0-9]+")
    card_index="${card_index#"${card_index%%[![:space:]]*}"}"
    echo $card_index
}

sleep 2

card_index=$(get_sound_card_index)
if [ -z "$card_index" ]; then
    echo "❌ Аудиокарта sof-hda-dsp не найдена"
    exit 1
fi

old_status=0

while true; do
    if amixer "-c${card_index}" get Headphone | grep -q "off"; then
        status=1
        move_output_to_speaker
    else
        status=2
        move_output_to_headphones
    fi

    if [ "$status" != "$old_status" ]; then
        if [ "$status" == "1" ]; then
            echo "🎧 Наушники отключены - звук через динамики"
            switch_to_speaker
        else
            echo "🎧 Наушники подключены - звук через наушники"
            switch_to_headphones
        fi
        old_status=$status
    fi

    sleep 0.3
done
