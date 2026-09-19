#!/usr/bin/env bash
# Reuse Arch host tools instead of rebuilding their Buildroot host packages.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILDROOT_DIR=${1:-${ROOT}/.buildroot/current}
OUTPUT_DIR=${2:-${ROOT}/output}
HOST_DIR=${OUTPUT_DIR}/host
BUILD_DIR=${OUTPUT_DIR}/build

command -v readlink >/dev/null
BUILDROOT_DIR=$(readlink -f "${BUILDROOT_DIR}")

require_tool() {
    command -v "$1" >/dev/null || {
        echo "Missing system host tool: $1" >&2
        exit 1
    }
}

link_tool() {
    local name=$1
    local source
    local destination=${HOST_DIR}/bin/${name}

    source=$(command -v "${name}")
    if [ -e "${destination}" ] && [ ! -L "${destination}" ]; then
        return
    fi
    ln -sfn "${source}" "${destination}"
}

link_tool_force() {
    local name=$1
    local source
    local destination=${HOST_DIR}/bin/${name}

    source=$(command -v "${name}")
    rm -f "${destination}"
    ln -s "${source}" "${destination}"
}

link_alias() {
    local name=$1
    local source=$2
    local destination=${HOST_DIR}/bin/${name}

    if [ -e "${destination}" ] && [ ! -L "${destination}" ]; then
        return
    fi
    ln -sfn "${source}" "${destination}"
}

write_host_python_wrapper() {
    local system_python
    local python_version
    local destination=${HOST_DIR}/bin/python3

    system_python=$(command -v python3)
    python_version=$("${system_python}" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    rm -f "${destination}"
    cat >"${destination}" <<EOF
#!/usr/bin/env bash
host_dir=\$(cd "\$(dirname "\$0")/.." && pwd)
site_packages=\$(find "\${host_dir}/lib" -maxdepth 2 -type d -name site-packages -print 2>/dev/null | paste -sd: -)
if [ -n "\${site_packages}" ]; then
    export PYTHONPATH="\${site_packages}\${PYTHONPATH:+:\${PYTHONPATH}}"
fi
exec "${system_python}" "\$@"
EOF
    chmod 0755 "${destination}"

    rm -f "${HOST_DIR}/bin/python"
    ln -s python3 "${HOST_DIR}/bin/python"
    ln -sfn python3 "${HOST_DIR}/bin/python${python_version}"
    ln -sfn python3-config "${HOST_DIR}/bin/python${python_version}-config"
}

link_sbin_tool() {
    local name=$1
    local source
    local destination=${HOST_DIR}/sbin/${name}

    source=$(command -v "${name}")
    if [ -e "${destination}" ] && [ ! -L "${destination}" ]; then
        return
    fi
    ln -sfn "${source}" "${destination}"
}

package_version() {
    local package_file=$1
    local variable=$2
    local value
    local referenced

    value=$(sed -nE "s/^${variable}[[:space:]]*=[[:space:]]*([^[:space:]#]+).*/\\1/p" \
        "${BUILDROOT_DIR}/${package_file}" | head -n 1)
    [ -n "${value}" ] || {
        echo "Cannot determine ${variable} from ${package_file}" >&2
        exit 1
    }

    while [[ "${value}" =~ \$\(([A-Z0-9_]+)\) ]]; do
        referenced=${BASH_REMATCH[1]}
        local replacement
        replacement=$(sed -nE "s/^${referenced}[[:space:]]*=[[:space:]]*([^[:space:]#]+).*/\\1/p" \
            "${BUILDROOT_DIR}/${package_file}" | head -n 1)
        [ -n "${replacement}" ] || {
            echo "Cannot expand ${referenced} in ${package_file}" >&2
            exit 1
        }
        value=${value//\$(${referenced})/${replacement}}
    done

    printf '%s\n' "${value}"
}

mark_host_package() {
    local package=$1
    local version=$2
    local package_dir=${BUILD_DIR}/host-${package}
    local stamp

    if [ -n "${version}" ]; then
        package_dir+=-${version}
    fi

    mkdir -p "${package_dir}"
    for stamp in \
        .stamp_actual_downloaded .stamp_downloaded .stamp_extracted .stamp_patched \
        .stamp_configured .stamp_built .stamp_host_installed .stamp_staging_installed \
        .stamp_target_installed .stamp_images_installed .stamp_installed; do
        touch "${package_dir}/${stamp}"
    done
}

ncurses_version() {
    local major
    local snapshot

    major=$(package_version package/ncurses/ncurses.mk NCURSES_VERSION_MAJOR)
    snapshot=$(package_version package/ncurses/ncurses.mk NCURSES_SNAPSHOT_DATE)
    printf '%s%s\n' "${major}" "${snapshot:+-${snapshot}}"
}

mkdir -p "${HOST_DIR}/bin" "${HOST_DIR}/sbin" "${HOST_DIR}/share" "${BUILD_DIR}"

# The first column is the executable name that Buildroot expects in HOST_DIR/bin.
for tool in \
    bison flex gperf gettext msgfmt xgettext autopoint makeinfo \
    make cmake meson ninja patchelf python3 python3-config fakeroot \
    gawk localedef mkpasswd openssl qemu-aarch64 cython \
    g-ir-scanner g-ir-compiler; do
    require_tool "${tool}"
    link_tool "${tool}"
done

# Buildroot installs a few pure-Python build modules into HOST_DIR. Keep using
# the system interpreter, but give it that private site-packages directory.
write_host_python_wrapper

# Autotools components must remain one Buildroot-versioned suite. Generated
# makefiles such as ALSA Utils request automake-1.16 explicitly, which is not
# interchangeable with Arch's newer Automake.

# The ext4 image backend invokes this fixed HOST_DIR path. Reuse Arch's
# e2fsprogs rather than building host-e2fsprogs and host-util-linux.
require_tool mkfs.ext4
link_sbin_tool mkfs.ext4
require_tool depmod
link_sbin_tool depmod

mark_host_package bison "$(package_version package/bison/bison.mk BISON_VERSION)"
mark_host_package flex "$(package_version package/flex/flex.mk FLEX_VERSION)"
mark_host_package gperf "$(package_version package/gperf/gperf.mk GPERF_VERSION)"
mark_host_package make "$(package_version package/make/make.mk MAKE_VERSION)"
mark_host_package cmake "$(package_version package/cmake/cmake.mk CMAKE_VERSION)"
mark_host_package meson "$(package_version package/meson/meson.mk MESON_VERSION)"
mark_host_package ninja "$(package_version package/ninja/ninja.mk NINJA_VERSION)"
mark_host_package patchelf "$(package_version package/patchelf/patchelf.mk PATCHELF_VERSION)"
mark_host_package python3 "$(package_version package/python3/python3.mk PYTHON3_VERSION)"

# The system Python is already linked with these. They are Buildroot's private
# host-Python dependencies, not target libraries; target libffi remains real.
mark_host_package expat "$(package_version package/expat/expat.mk EXPAT_VERSION)"
mark_host_package libzlib "$(package_version package/libzlib/libzlib.mk LIBZLIB_VERSION)"
mark_host_package zlib ""
mark_host_package ncurses "$(ncurses_version)"
mark_host_package util-linux "$(package_version package/util-linux/util-linux.mk UTIL_LINUX_VERSION)"
mark_host_package e2fsprogs "$(package_version package/e2fsprogs/e2fsprogs.mk E2FSPROGS_VERSION)"
mark_host_package attr "$(package_version package/attr/attr.mk ATTR_VERSION)"
mark_host_package acl "$(package_version package/acl/acl.mk ACL_VERSION)"
mark_host_package fakeroot "$(package_version package/fakeroot/fakeroot.mk FAKEROOT_VERSION)"
mark_host_package gawk "$(package_version package/gawk/gawk.mk GAWK_VERSION)"
mark_host_package gettext ""
mark_host_package gettext-tiny "$(package_version package/gettext-tiny/gettext-tiny.mk GETTEXT_TINY_VERSION)"
mark_host_package kmod "$(package_version package/kmod/kmod.mk KMOD_VERSION)"
mark_host_package localedef "$(package_version package/localedef/localedef.mk LOCALEDEF_VERSION)"
mark_host_package mkpasswd ""
mark_host_package openssl ""
mark_host_package libxcrypt "$(package_version package/libxcrypt/libxcrypt.mk LIBXCRYPT_VERSION)"

# Python GI requires these tools only while generating target typelibs. Their
# Arch versions provide the same host-side interfaces, including qemu-aarch64.
mark_host_package qemu "$(package_version package/qemu/qemu.mk QEMU_VERSION)"
mark_host_package pixman "$(package_version package/pixman/pixman.mk PIXMAN_VERSION)"
mark_host_package slirp "$(package_version package/slirp/slirp.mk SLIRP_VERSION)"
mark_host_package python-cython "$(package_version package/python-cython/python-cython.mk PYTHON_CYTHON_VERSION)"
mark_host_package python-distlib "$(package_version package/python-distlib/python-distlib.mk PYTHON_DISTLIB_VERSION)"

# Pure-Python build modules are installed by Buildroot into output/host. They
# are small and must be real: target recipes invoke ``python3 -m build``.

echo "Prepared system host tools in ${HOST_DIR}"
