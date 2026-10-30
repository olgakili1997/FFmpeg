#!/bin/bash
# Usage: ./make_reels.sh  (needs ffmpeg, python3, network access to Yandex Disk)
set -e; cd "$(dirname "$0")"; mkdir -p seg
PK="https://disk.yandex.ru/d/VpFuIp6jTxcDdw"
FONT=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
href() { python3 -c "import json,sys,urllib.request,urllib.parse;print(json.load(urllib.request.urlopen('https://cloud-api.yandex.net/v1/disk/public/resources/download?'+urllib.parse.urlencode({'public_key':sys.argv[1],'path':sys.argv[2]})))['href'])" "$PK" "$1"; }
while IFS='|' read n p s d; do
  ffmpeg -v error -y -ss $s -i "$(href "$p")" -t $d -vf "scale=1080:1920:flags=lanczos,fps=30,format=yuv420p" \
    -c:v libx264 -crf 12 -preset fast -c:a aac -ar 48000 -ac 2 -b:a 192k "seg/$n.mp4"
done < edl.txt
build() { r=$1; title="$2"; out=$3
  files=(seg/${r}_*.mp4); n=${#files[@]}; in=""; fc=""; cat=""
  for i in "${!files[@]}"; do in="$in -i ${files[$i]}"; d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 ${files[$i]})
    fc="$fc[$i:v]setpts=PTS-STARTPTS[v$i];[$i:a]asetpts=PTS-STARTPTS,afade=t=in:d=0.03,afade=t=out:st=$(python3 -c "print($d-0.04)"):d=0.04[a$i];"; cat="$cat[v$i][a$i]"; done
  fc="$fc${cat}concat=n=$n:v=1:a=1[cv][ca];[cv]eq=contrast=1.06:saturation=1.12,unsharp=5:5:0.4,drawbox=y=ih*0.1-20:w=iw:h=170:color=black@0.45:t=fill:enable='lt(t,2.2)',drawtext=fontfile=$FONT:text='$title':fontcolor=white:fontsize=78:x=(w-tw)/2:y=h*0.1:enable='lt(t,2.2)',drawbox=y=ih*0.78-20:w=iw:h=170:color=black@0.45:t=fill:enable='gte(t,8.5)',drawtext=fontfile=$FONT:text='А-А-А ДЕТЕЙЛИНГ':fontcolor=white:fontsize=78:x=(w-tw)/2:y=h*0.78:enable='gte(t,8.5)',fade=t=in:d=0.25,fade=t=out:st=9.6:d=0.4[ov];[ca]loudnorm=I=-16:TP=-1.5,afade=t=out:st=9.4:d=0.6[oa]"
  ffmpeg -v error -y $in -filter_complex "$fc" -map "[ov]" -map "[oa]" -t 10 -c:v libx264 -preset slow -crf 18 -profile:v high \
    -pix_fmt yuv420p -r 30 -c:a aac -b:a 192k -ar 48000 -movflags +faststart "$out"
}
build r1 'МОЙКА MAYBACH' detailing_01_moika_maybach.mp4
build r2 'КЕРАМИКА КУЗОВА' detailing_02_keramika_g-class.mp4
build r3 'МОЙКА МОТОЦИКЛА' detailing_03_moika_harley.mp4
build r4 'ТОНИРОВКА СТЁКОЛ' detailing_04_tonirovka_vw.mp4
