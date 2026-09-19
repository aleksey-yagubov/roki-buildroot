#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cache_dir="$repo_root/.buildroot"
api_url="https://api.github.com/repos/buildroot/buildroot/commits/master"

sha=$(curl --fail --location --silent --show-error "$api_url" |
    sed -n 's/^[[:space:]]*"sha": "\([0-9a-f]\{40\}\)",$/\1/p' | head -n 1)

if [ -z "$sha" ]; then
    echo "Could not resolve Buildroot master SHA." >&2
    exit 1
fi

tree="$cache_dir/buildroot-$sha"
archive="$cache_dir/buildroot-$sha.tar.gz"

if [ ! -d "$tree" ]; then
    mkdir -p "$cache_dir"
    if [ ! -f "$archive" ]; then
        curl --fail --location --show-error \
            "https://github.com/buildroot/buildroot/archive/$sha.tar.gz" \
            -o "$archive"
    fi

    temporary="$cache_dir/.extract-$sha-$$"
    rm -rf "$temporary"
    mkdir "$temporary"
    tar -xzf "$archive" --strip-components=1 -C "$temporary"
    mv "$temporary" "$tree"
fi

mkdir -p "$tree/.roki-patches"
for patch_file in "$repo_root"/patches/buildroot/*.patch; do
    [ -e "$patch_file" ] || continue
    patch_marker="$tree/.roki-patches/$(basename "$patch_file").applied"
    if [ ! -f "$patch_marker" ]; then
        patch -d "$tree" -p1 --batch < "$patch_file"
        : > "$patch_marker"
    fi
done

ln -sfn "buildroot-$sha" "$cache_dir/current"
printf '%s\n' "Buildroot master: $sha"
printf '%s\n' "Source tree: $tree"
