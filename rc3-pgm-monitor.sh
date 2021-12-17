#!/bin/sh

set -euxo pipefail

FONT='/opt/comic.ttf'
STREAM="${1:-pgm}"
STREAM_OUT_SUFFIX="${2:-monitor}"
KEY_PLAY=$(cat /opt/srt_play)
KEY_PUBLISH=$(cat /opt/srt_publish)
SRT_HOST="srt://srt.mon2.de:20000"

ffmpeg -y -i "${SRT_HOST}?streamid=play/$STREAM/${KEY_PLAY}" \
  -nostats -progress "/tmp/ffmpeg/${STREAM}_${STREAM_OUT_SUFFIX}" -loglevel repeat+level+info \
  -filter_complex \
 "[0:a:0]ebur128=video=1:meter=18:target=-14[native][native_a]; [native_a]anullsink; \
  [native]drawtext=fontfile=$FONT:text=native:fontcolor=white:fontsize=60:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=(h-text_h)/1.5[native_overlay];\
  [0:a:0]showvolume=r=50:w=640:h=20:b=0:ds=log:dm=1.0[native_vu]; \
  [0:a:1]ebur128=video=1:meter=18:target=-14[lingo1][lingo1_a]; [lingo1_a]anullsink; \
  [lingo1]drawtext=fontfile=$FONT:text=lingo1:fontcolor=white:fontsize=60:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=(h-text_h)/1.5[lingo1_overlay];\
  [0:a:1]showvolume=r=50:w=640:h=20:b=0:ds=log:dm=1.0[lingo1_vu]; \
  [0:a:2]ebur128=video=1:meter=18:target=-14[lingo2][lingo2_a]; [lingo2_a]anullsink; \
  [lingo2]drawtext=fontfile=$FONT:text=lingo2:fontcolor=white:fontsize=60:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=(h-text_h)/1.5[lingo2_overlay];\
  [0:a:2]showvolume=r=50:w=640:h=20:b=0:ds=log:dm=1.0[lingo2_vu]; \
  [native_overlay][lingo1_overlay][lingo2_overlay]hstack=inputs=3[ebu_mix]; \
  [0:v:0]drawtext=fontfile=$FONT:text=$STREAM:fontcolor=white:fontsize=100:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=(h-text_h)/1.5[preview_overlay];\
  [native_vu][lingo1_vu][lingo2_vu]hstack=inputs=3[vu_mix]; \
  [preview_overlay][vu_mix][ebu_mix]vstack=inputs=3[full_mix];[full_mix]framerate=fps=25[out]" \
  -map "[out]" \
  -g 75 \
  -c:v libx264 -preset ultrafast -f mpegts "${SRT_HOST}?streamid=publish/${STREAM}_${STREAM_OUT_SUFFIX}/${KEY_PUBLISH}"
