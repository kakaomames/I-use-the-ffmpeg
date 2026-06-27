#!/bin/bash

# ==============================================================================
# ⚠️ WARNING / 免責事項 (DISCLAIMER)
# ==============================================================================
# 本スクリプトは個人の学習およびバックアップ目的でのみ使用してください。
# 悪用厳禁です。各プラットフォームの利用規約（ToS）を必ず遵守してください。
# 本スクリプトを利用したことによるアカウント停止、法的トラブル、いかなる損害についても、
# 開発者は一切の責任を負いません。
# 使い方を誤った場合の責任はすべて利用者が負うものとします。
# 文句やクレームは一切受け付けません。自己責任で利用してください。
# ==============================================================================

# 1. ターミナルへ警告を表示 (実行時に必ず目に入るようにする)
echo "=============================================================================="
echo "⚠️ WARNING / DISCLAIMER"
echo "このスクリプトの利用は自己責任です。利用者は各サービスの利用規約を遵守し、"
echo "悪用を行わないことに同意したものとみなします。開発者は一切の責任を負いません。"
echo "=============================================================================="

# 2. ログ初期化 (ログファイルにも同じ警告を記録)
cat << 'EOF' > log.txt
==============================================================================
⚠️ WARNING / DISCLAIMER
==============================================================================
本スクリプトは個人の学習およびバックアップ目的でのみ使用してください。
悪用厳禁です。各プラットフォームの利用規約（ToS）を必ず遵守してください。
本スクリプトを利用したことによるアカウント停止、法的トラブル、いかなる損害についても、
開発者は一切の責任を負いません。
使い方を誤った場合の責任はすべて利用者が負うものとします。
文句やクレームは一切受け付けません。自己責任で利用してください。
==============================================================================

==============================================================================
      AUTO-DETECTION MISSION START!!
==============================================================================
EOF

# 必要なファイルの確認
if [ ! -f "url.json" ]; then
    echo "[$(date)] ERROR: url.json not found." >> log.txt
    exit 0
fi

mkdir -p output

# JSONの長さを取得
length=$(jq '.urls | length' url.json)

for ((i=0; i<$length; i++)); do
    landing_url=$(jq -r ".urls[$i].url" url.json)
    filename=$(jq -r ".urls[$i].name" url.json)

    echo "[$(date)] Searching for stream in: $landing_url" >> log.txt

    # 1. ページ内容を一時保存
    if ! curl -sL "$landing_url" > .temp_page.txt; then
        echo "[$(date)] ERROR: Failed to fetch landing page for $filename" >> log.txt
        continue
    fi

    # 2. grepでm3u8 URLを抽出
    stream_url=$(grep -oE 'https?://[^"]+\.m3u8(\?[^"]+)?' .temp_page.txt | head -n 1)

    # 3. URLが取れなかった場合
    if [ -z "$stream_url" ]; then
        echo "[$(date)] ERROR: No m3u8 stream found in $landing_url" >> log.txt
        rm -f .temp_page.txt
        continue
    fi

    echo "[$(date)] Found stream: $stream_url" >> log.txt

    # 4. 見つけたURLをffmpegに流し込んでクローン
    if ! ffmpeg -i "$stream_url" -c copy -hls_list_size 0 -f hls "output/${filename}.m3u8" 2>> log.txt; then
        echo "[$(date)] ERROR: Cloning failed for $filename" >> log.txt
    else
        echo "[$(date)] SUCCESS: $filename cloned successfully!" >> log.txt
    fi

    # 掃除
    rm -f .temp_page.txt
done

echo "[$(date)] Mission Completed." >> log.txt
exit 0
