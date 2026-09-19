#!/bin/sh
# Buildroot calls its HTTP downloader as: <command> -O <output> <url>.
# Listed hosts use curl through SOCKS; every other host stays on direct wget.
set -eu

proxy=${ROKI_DOWNLOAD_PROXY:-}
proxy_hosts=${ROKI_DOWNLOAD_PROXY_HOSTS:-}

output=
while getopts 'O:' option; do
    case "$option" in
        O) output=$OPTARG ;;
    esac
done
shift $((OPTIND - 1))

if [ -n "$proxy" ] && [ -n "$proxy_hosts" ] && [ "$#" -eq 1 ]; then
    authority=${1#*://}
    authority=${authority%%/*}
    host=${authority%%:*}
    case ",$proxy_hosts," in
        *,"$host",*)
            [ -n "$output" ] || {
                echo "wget-download.sh: missing output path" >&2
                exit 2
            }
            exec curl --fail --location --retry 3 --connect-timeout 10 \
                --proxy "$proxy" --output "$output" "$1"
            ;;
    esac
fi

[ -n "$output" ] && [ "$#" -eq 1 ] || {
    echo "wget-download.sh: expected -O <output> <url>" >&2
    exit 2
}

exec wget -nd -t 3 --connect-timeout=10 -O "$output" "$1"
