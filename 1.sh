#!/bin/bash

# --- 準備 ---
if [ ! -f "url.json" ]; then exit 1; fi
mkdir -p output

while [ "$(jq '.urls | length' url.json)" -gt 0 ]; do
    item=$(jq -c '.urls[0]' url.json)
    target_url=$(echo "$item" | jq -r '.url')
    name=$(echo "$item" | jq -r '.name')
    out_dir="output/$name"
    mkdir -p "$out_dir"

    echo "[$(date)] Mission: Archiving $name" >> log.txt

    # 1. ページ取得
    if ! curl -sL "$target_url" > .temp_page.txt; then
        echo "[$(date)] ERROR: Fetch failed $name" >> log.txt
        jq 'del(.urls[0])' url.json > tmp.json && mv tmp.json url.json
        continue
    fi

    # 2. 動画URL抽出
    stream_url=$(grep -m 1 -oE 'https?://[^"]+\.(m3u8|mp4|webm)(\?[^"]+)?' .temp_page.txt)

    # 3. 分岐処理
    if [[ "$stream_url" == *".m3u8"* ]]; then
        echo "[$(date)] Mode: Archiving M3U8 & TS Segments" >> log.txt
        
        # マニフェスト取得
        curl -sL "$stream_url" > "$out_dir/index.m3u8"
        
        # TSファイルのダウンロード (マニフェストからhttpで始まる行を抽出して取得)
        # ※.ts で終わる行を対象にする
        grep -oE 'https?://[^"]+\.ts(\?[^"]+)?' "$out_dir/index.m3u8" | while read -r ts_url; do
            ts_filename=$(basename "$ts_url" | cut -d'?' -f1)
            curl -sL "$ts_url" -o "$out_dir/$ts_filename"
        done
        
        # 隊長ご指定の正規表現でパスを掃除 (http.../ を ./ に置換)
        sed -i 's|http[^ ]*/|./|g' "$out_dir/index.m3u8"
        
    elif [[ "$stream_url" =~ \.(mp4|webm)$ ]]; then
        echo "[$(date)] Mode: FFmpeg Conversion (HLS)" >> log.txt
        # MP4の場合は一度FFmpegで分割して保存する
        if ! ffmpeg -i "$stream_url" -c copy -hls_list_size 0 -hls_base_url "./" -f hls "$out_dir/index.m3u8" 2>> log.txt; then
            echo "[$(date)] ERROR: FFmpeg failed for $name" >> log.txt
        fi
    fi

    # 4. 完了処理
    rm -f .temp_page.txt
    jq 'del(.urls[0])' url.json > tmp.json && mv tmp.json url.json
done

echo "[$(date)] Mission Completed." >> log.txt
exit 0

