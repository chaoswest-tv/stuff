#!/bin/bash

set -euxo pipefail

FONT='/opt/comic.ttf'
STREAM="${1:-cwtv}"
STREAM_OUT_SUFFIX="monitor"
SRT_SRC_HOST="srt://ingest${2:-}.c3voc.de:1337"
SRT_DST_HOST="srt://127.0.0.1:1337"

ffmpeg -y -i "${SRT_SRC_HOST}?streamid=play/$STREAM" \
  -nostats -progress "/tmp/ffmpeg/${STREAM}_${STREAM_OUT_SUFFIX}" -loglevel repeat+level+info \
  -filter_complex \
 "[0:v:0]scale=640x360[orig_scaled]; \
  [0:a:0]ebur128=video=1:size=640x480:meter=9:target=-16:gauge=shortterm[native][native_a]; [native_a]anullsink; \
  [0:a:1]ebur128=video=1:size=640x480:meter=9:target=-16:gauge=shortterm[lingo1][lingo1_a]; [lingo1_a]anullsink; \
  [0:a:2]ebur128=video=1:size=640x480:meter=9:target=-16:gauge=shortterm[lingo2][lingo2_a]; [lingo2_a]anullsink; \
  [native]drawtext=fontfile=$FONT:text=native:fontcolor=white:fontsize=60:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=(h-text_h)/1.5[native_overlay];\
  [lingo1]drawtext=fontfile=$FONT:text=lingo1:fontcolor=white:fontsize=60:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=(h-text_h)/1.5[lingo1_overlay];\
  [lingo2]drawtext=fontfile=$FONT:text=lingo2:fontcolor=white:fontsize=60:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=(h-text_h)/1.5[lingo2_overlay];\
  [0:a:0]showvolume=r=50:w=640:h=20:b=0:ds=log:dm=1.0[native_vu]; \
  [0:a:1]showvolume=r=50:w=640:h=20:b=0:ds=log:dm=1.0[lingo1_vu]; \
  [0:a:2]showvolume=r=50:w=640:h=20:b=0:ds=log:dm=1.0[lingo2_vu]; \
  [orig_scaled][native_vu][lingo1_vu][lingo2_vu]vstack=inputs=4[left_top]; \
  [left_top]drawtext=fontfile=$FONT:text=$STREAM:fontcolor=white:fontsize=100:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=(h-text_h)/1.5[left_top_overlay];\
  [left_top_overlay][native_overlay]vstack=inputs=2[left]; \
  [lingo1_overlay][lingo2_overlay]vstack=inputs=2[right]; \
  [left][right]hstack=inputs=2[full_mix];[full_mix]framerate=fps=10[out]" \
  -map "[out]" \
  -g 30 \
  -c:v libx264 -preset ultrafast -f mpegts "${SRT_DST_HOST}?streamid=publish/${STREAM}_${STREAM_OUT_SUFFIX}"
