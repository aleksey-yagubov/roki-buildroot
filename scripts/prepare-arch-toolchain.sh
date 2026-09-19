#!/usr/bin/env bash
# Expose only the external-toolchain frontends needed by this configuration.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PREFIX=aarch64-linux-gnu
BUILDROOT_TRIPLET=aarch64-buildroot-linux-gnu
WRAPPER_DIR=${ROOT}/.toolchain/archlinux-aarch64
OUTPUT_WRAPPER_DIR=${ROOT}/output/host/bin
TARGET_OPTIMIZATION=$(sed -n 's/^BR2_TARGET_OPTIMIZATION="\(.*\)"$/\1/p' \
    "${ROOT}/output/.config" 2>/dev/null || true)

for tool in gcc g++ cpp ar as ld nm objcopy objdump ranlib readelf strip gcc-ar gcc-nm gcc-ranlib; do
    command -v "${PREFIX}-${tool}" >/dev/null || {
        echo "Missing host tool: ${PREFIX}-${tool}" >&2
        exit 1
    }
done

if [ -d "${WRAPPER_DIR}/sysroot" ]; then
    rm -rf "${WRAPPER_DIR}"
fi
mkdir -p "${WRAPPER_DIR}/bin"
mkdir -p "${OUTPUT_WRAPPER_DIR}"

for tool in gcc g++ cpp ar as ld nm objcopy objdump ranlib readelf strip gcc-ar gcc-nm gcc-ranlib; do
    tool_path="${WRAPPER_DIR}/bin/${PREFIX}-${tool}"
    if [ "${tool}" = gcc ] || [ "${tool}" = g++ ] || [ "${tool}" = cpp ]; then
        [ ! -L "${tool_path}" ] || unlink "${tool_path}"
        cat >"${tool_path}" <<EOF
#!/usr/bin/env bash
# Use Buildroot's staging sysroot for target compilation. During the initial
# external-toolchain probe it is still empty, so temporarily use Arch's own.
staging_sysroot="${ROOT}/output/host/${BUILDROOT_TRIPLET}/sysroot"
toolchain_stamp="${ROOT}/output/build/toolchain-external-custom/.stamp_configured"
if [ -f "\${toolchain_stamp}" ] && { [ -e "\${staging_sysroot}/usr/lib/libc.so" ] || [ -e "\${staging_sysroot}/lib/libc.so.6" ]; }; then
    active_sysroot="\${staging_sysroot}"
else
    active_sysroot="/usr/${PREFIX}"
fi
for arg in "\$@"; do
    case "\$arg" in
        -print-*|-dumpmachine|-dumpversion|-dumpfullversion)
            exec /usr/bin/${PREFIX}-${tool} "\$@"
            ;;
    esac
done
case "\$PWD" in
    "${ROOT}"/output/build/linux-custom*)
        # Kbuild owns kernel optimisation policy and deliberately uses -O2.
        exec /usr/bin/${PREFIX}-${tool} \\
            --sysroot="\${active_sysroot}" \\
            -isystem "\${active_sysroot}/usr/include" "\$@"
        ;;
esac
exec /usr/bin/${PREFIX}-${tool} \\
    --sysroot="\${active_sysroot}" \\
    -isystem "\${active_sysroot}/usr/include" \\
    -L"\${active_sysroot}/usr/lib" \\
    -L"\${active_sysroot}/lib" \\
    "\$@" ${TARGET_OPTIMIZATION}
EOF
        chmod +x "${tool_path}"
    else
        ln -sfn "/usr/bin/${PREFIX}-${tool}" "${tool_path}"
    fi
    ln -sfn "${WRAPPER_DIR}/bin/${PREFIX}-${tool}" "${OUTPUT_WRAPPER_DIR}/${PREFIX}-${tool}"
done
