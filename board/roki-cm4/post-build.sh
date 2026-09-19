#!/bin/sh

set -eu

target_dir="$1"
build_date="$(LC_ALL=C TZ=Europe/Moscow date '+%Y-%m-%d %H:%M:%S MSK')"

printf '%s\n' "${build_date}" > "${target_dir}/etc/roki-build-date"
