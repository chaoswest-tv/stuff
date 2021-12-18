#!/bin/sh

set -euxo pipefail

SOURCE="${1:-pgm}"
STREAM="${2:-cwtv}"
KEY_PLAY=$(cat /opt/srt_play)
KEY_PUBLISH=$(cat /opt/srt_publish)

mkdir -p "/opt/hls/data/$STREAM"

ffmpeg -y -i "srt://*****?streamid=play/${SOURCE}/$KEY_PLAY" \
  -nostats -progress "/tmp/ffmpeg/${STREAM}_hls" -loglevel repeat+level\
  -map 0:v:0 -map 0:a:0 \
  -map 0:v:0 -map 0:a:0 \
  -map 0:v:0 -map 0:a:0 \
  -map 0:a:0 -map 0:a:1 -map 0:a:2 \
  -g 75 \
  -c:v libx264 -crf 21 -c:a aac -ar 48000 -preset fast \
  -maxrate:v:0 6000k -b:a:0 192k \
  -filter:v:1 scale=w=1280:h=-2  -maxrate:v:1 2500k -b:a:1 192k \
  -filter:v:2 scale=w=848:h=-2  -maxrate:v:2 1000k -b:a:2 192k \
  -b:a:3 192k -b:a:4 192k -b:a:5 192k \
  -var_stream_map "v:0,a:0,name:1080p,agroup:main v:1,a:1,name:720p,agroup:main v:2,a:2,name:480p,agroup:main a:3,agroup:main,name:native,default:yes,language:Native a:4,agroup:main,name:lingo1,language:Translation_1 a:5,agroup:main,name:lingo2,language:Translation_2" \
  -f hls -hls_time 6 -hls_list_size 100 -master_pl_publish_rate 5 -hls_flags +delete_segments+append_list+omit_endlist+independent_segments+temp_file -hls_allow_cache 0 \
  -hls_start_number_source epoch -strftime 1 -hls_segment_filename "/opt/hls/data/$STREAM/%v-%Y%m%d-%s.ts" \
  -master_pl_name "main.m3u8" "/opt/hls/data/$STREAM/%v.m3u8" \
  -vf fps=1 -update 1 "/opt/hls/data/$STREAM/poster.png"
