#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <roki-mb-interface commit-or-tag>" >&2
	exit 2
fi

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
recipe="$repo_root/package/roki-mb-interface/roki-mb-interface.mk"
source_repo=https://github.com/tndrd/roki-mb-interface.git
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

git -C "$workdir" init -q
git -C "$workdir" fetch -q --depth=1 "$source_repo" "$1"
main_commit=$(git -C "$workdir" rev-parse FETCH_HEAD)

gitlink() {
	git -C "$workdir" ls-tree "$main_commit" "deps/$1" | awk '{ print $3 }'
}

rcb4_commit=$(gitlink rcb4-base-class)
mb_service_commit=$(gitlink roki-mb-service)

if [ -z "$rcb4_commit" ] || [ -z "$mb_service_commit" ]; then
	echo "Required submodule gitlink is absent in $main_commit" >&2
	exit 1
fi

sed -i \
	-e "s/^ROKI_MB_INTERFACE_VERSION = .*/ROKI_MB_INTERFACE_VERSION = $main_commit/" \
	-e "s/^ROKI_MB_INTERFACE_RCB4_VERSION = .*/ROKI_MB_INTERFACE_RCB4_VERSION = $rcb4_commit/" \
	-e "s/^ROKI_MB_INTERFACE_MB_SERVICE_VERSION = .*/ROKI_MB_INTERFACE_MB_SERVICE_VERSION = $mb_service_commit/" \
	"$recipe"

printf 'roki-mb-interface: %s\nrcb4-base-class: %s\nroki-mb-service: %s\n' \
	"$main_commit" "$rcb4_commit" "$mb_service_commit"
