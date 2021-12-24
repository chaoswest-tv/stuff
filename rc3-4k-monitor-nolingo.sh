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
 "[0:v:0]scale=640x360[orig_scaled];\
  [orig_scaled]drawtext=fontfile=$FONT:text=$STREAM:fontcolor=white:fontsize=100:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=(h-text_h)/1.5[preview_overlay];\
  [0:a:0]ebur128=video=1:size=640x480:meter=9:target=-16:gauge=shortterm[native][native_a]; [native_a]anullsink; \
  [native]drawtext=fontfile=$FONT:text=native:fontcolor=white:fontsize=60:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=(h-text_h)/1.5[native_overlay];\
  [0:a:0]showvolume=r=50:w=640:h=60:b=0:ds=log:dm=1.0[native_vu]; \
  [preview_overlay][native_vu][native_overlay]vstack=inputs=3[full_mix]; \
  [full_mix]framerate=fps=10[out]" \
  -map "[out]" \
  -g 30 \
  -c:v libx264 -preset ultrafast -f mpegts "${SRT_DST_HOST}?streamid=publish/${STREAM}_${STREAM_OUT_SUFFIX}"
