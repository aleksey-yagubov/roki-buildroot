#!/bin/sh

set -eu

destination_host="${1:-172.30.0.2}"

exec gst-launch-1.0 -q \
    libcamerasrc sensor-config='sensor/config,width=1600,height=1300,depth=10' \
    ! 'video/x-raw,format=NV12,width=800,height=650,framerate=60/1' \
    ! v4l2convert disable-passthrough=true \
    ! 'video/x-raw,format=I420' \
    ! v4l2h264enc extra-controls='controls,video_bitrate_mode=0,video_bitrate=2000000,repeat_sequence_header=1' \
    ! 'video/x-h264,profile=high,level=(string)4.2' \
    ! rtph264pay config-interval=1 pt=96 \
    ! udpsink host="${destination_host}" port=5000 sync=false
