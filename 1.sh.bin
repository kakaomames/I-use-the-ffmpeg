#!/bin/bash

# --- 免責事項の出力 (ログ用) ---
cat << 'EOF' > log.txt
==============================================================================
⚠️ WARNING / DISCLAIMER
==============================================================================
本システムは個人の学習およびバックアップ目的でのみ使用しています。
悪用厳禁です。各プラットフォームの利用規約を遵守してください。
生成されたコンテンツの利用における法的トラブル等について、責任は一切負いません。
==============================================================================
EOF
rm -f .temp_page.txt
# log.txtはGit管理したくないなら消す、残したいなら.gitignoreへ

# --- 必要なファイルの確認 ---
if [ ! -f "url.json" ]; then
    echo "[$(date)] ERROR: url.json not found." >> log.txt
    exit 0
fi

mkdir -p output

# --- 順次処理ループ ---
while true; do
    # JSONの先頭要素を取得
    item=$(jq -c '.urls[0]' url.json)
    
    # 処理すべき要素がなければ終了
    if [ "$item" == "null" ]; then
        echo "[$(date)] All tasks completed!" >> log.txt
        break
    fi

    # URLと名前を取り出し
    target_url=$(echo $item | jq -r '.url')
    filename=$(echo $item | jq -r '.name')

    echo "[$(date)] Processing: $filename" >> log.txt

    # 1. ページ取得 (クローン)
    # ここでストリームURLをgrepで抽出
    if ! curl -sL "$target_url" > .temp_page.txt; then
        echo "[$(date)] ERROR: Failed to fetch $filename" >> log.txt
        break # エラー時は無限ループ防止のため停止
    fi

    stream_url=$(grep -m 1 -oE 'https?://[^"]+\.m3u8(\?[^"]+)?' .temp_page.txt)
    
    if [ -z "$stream_url" ]; then
        echo "[$(date)] ERROR: m3u8 not found for $filename" >> log.txt
        rm -f .temp_page.txt
        # 処理できないものは消して次へ進む(必要に応じて調整)
        jq 'del(.urls[0])' url.json > temp.json && mv temp.json url.json
        continue
    fi

    # 2. FFmpegで変換
    if ffmpeg -i "$stream_url" -c copy -hls_list_size 0 -hls_base_url "./" -f hls "output/${filename}.m3u8" 2>> log.txt; then
        echo "[$(date)] SUCCESS: $filename completed." >> log.txt
        
        # 3. 成功時のみJSONから該当要素を削除
        jq 'del(.urls[0])' url.json > temp.json && mv temp.json url.json
    else
        echo "[$(date)] ERROR: FFmpeg failed for $filename" >> log.txt
        break # 失敗時は停止
    fi

    rm -f .temp_page.txt
done

echo "[$(date)] Mission Completed." >> log.txt
exit 0
