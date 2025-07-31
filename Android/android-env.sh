#!/usr/bin/env bash
# android-env.sh
#
# Este script deve ser **sourced** com as variáveis de ambiente abaixo já definidas:
#   ANDROID_HOME - Caminho para o Android SDK
#   HOST         - Triplo GNU target (ex: arm-linux-androideabi)
#
# Variáveis opcionais que podem ser sobrescritas antes do uso:
#   ANDROID_API_LEVEL - API mínima do Android para o build (padrão: 24)
#   PREFIX            - Caminho onde buscar bibliotecas necessárias

set -euo pipefail

: "${ANDROID_HOME:?Environment variable ANDROID_HOME must be set}"
: "${HOST:?Environment variable HOST must be set}"
ANDROID_API_LEVEL="${ANDROID_API_LEVEL:-24}"
PREFIX="${PREFIX:-}"

log() {
    echo "[android-env] $1" >&2
}

fail() {
    log "ERROR: $1"
    exit 1
}

# NDK versão suportada
ndk_version="27.2.12479018"
ndk_path="$ANDROID_HOME/ndk/$ndk_version"

if [ ! -d "$ndk_path" ]; then
    log "NDK $ndk_version não encontrado. Instalando via sdkmanager..."
    yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" "ndk;$ndk_version"
fi

# Ajuste do triplet clang para armv7a no Android
if [ "$HOST" = "arm-linux-androideabi" ]; then
    clang_triplet="armv7a-linux-androideabi"
else
    clang_triplet="$HOST"
fi

# Definindo caminho para toolchain clang baseado na instalação do NDK
toolchain_path=$(echo "$ndk_path/toolchains/llvm/prebuilt/"*/bin | awk '{print $1}' | xargs dirname)

export AR="$toolchain_path/llvm-ar"
export AS="$toolchain_path/llvm-as"
export CC="$toolchain_path/${clang_triplet}${ANDROID_API_LEVEL}-clang"
export CXX="${CC}++"
export LD="$toolchain_path/ld"
export NM="$toolchain_path/llvm-nm"
export RANLIB="$toolchain_path/llvm-ranlib"
export READELF="$toolchain_path/llvm-readelf"
export STRIP="$toolchain_path/llvm-strip"

# Verifica se as ferramentas existem
for tool in AR AS CC CXX LD NM RANLIB READELF STRIP; do
    path="${!tool}"
    if [ ! -x "$path" ]; then
        fail "Ferramenta $tool não encontrada ou não executável: $path"
    fi
done

# Flags padrões para compilação
export CFLAGS="-D__BIONIC_NO_PAGE_SIZE_MACRO"
export LDFLAGS="-Wl,--build-id=sha1 -Wl,--no-rosegment -Wl,-z,max-page-size=16384"

# Flag para evitar símbolos indefinidos em tempo de link
LDFLAGS+=" -Wl,--no-undefined"

# Linkar biblioteca matemática explicitamente, requisito do Android
LDFLAGS+=" -lm"

# Ajustes específicos para ARM 32 bits
if [ "$HOST" = "arm-linux-androideabi" ]; then
    CFLAGS+=" -march=armv7-a -mthumb"
fi

# Inclui caminhos para bibliotecas e includes adicionais se PREFIX estiver definido
if [ -n "$PREFIX" ]; then
    abs_prefix="$(realpath "$PREFIX")"
    CFLAGS+=" -I${abs_prefix}/include"
    LDFLAGS+=" -L${abs_prefix}/lib"

    export PKG_CONFIG="pkg-config --define-prefix"
    export PKG_CONFIG_LIBDIR="${abs_prefix}/lib/pkgconfig"
fi

# Para compilação C++, alguns sistemas usam apenas CXXFLAGS, outros combinam com CFLAGS
export CXXFLAGS="$CFLAGS"

# Detecta número de CPUs para paralelizar builds
if [ "$(uname)" = "Darwin" ]; then
    export CPU_COUNT="$(sysctl -n hw.ncpu)"
else
    export CPU_COUNT="$(nproc)"
fi

log "Configuração do ambiente Android concluída."
