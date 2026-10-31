#!/bin/bash
# Builds detailing_05_anshlag.mp4 from edl_anshlag.txt: id | disk path | start, s | source duration, s | speed
set -e; cd "$(dirname "$0")"; mkdir -p seg
PK="https://disk.yandex.ru/d/VpFuIp6jTxcDdw"
href() { python3 -c "import json,sys,urllib.request,urllib.parse;print(json.load(urllib.request.urlopen('https://cloud-api.yandex.net/v1/disk/public/resources/download?'+urllib.parse.urlencode({'public_key':sys.argv[1],'path':sys.argv[2]})))['href'])" "$PK" "$1"; }
while IFS='|' read n p s d k; do
  at=$(python3 -c "
k=$k; f=[]
while k>2: f.append('atempo=2.0'); k/=2
f.append(f'atempo={k}'); print(','.join(f))")
  ffmpeg -v error -y -ss $s -t $d -i "$(href "$p")" -vf "setpts=PTS/$k,scale=1080:1920:flags=lanczos,fps=30,format=yuv420p" -af "$at" \
    -c:v libx264 -crf 12 -preset fast -c:a aac -ar 48000 -ac 2 -b:a 192k "seg/$n.mp4"
done < edl_anshlag.txt
FONT=x; eval "$(sed -n '/^build()/,/^}/p' make_reels.sh)"
build a5 '' detailing_05_anshlag.mp4
