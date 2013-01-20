#!/bin/bash
#
# Copyright (C) 2010, 2012, 2013 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#  This shell script is used to rebuild the gcc and toolchain binaries
#  for the Android NDK.
#

# include common function and variable definitions
. `dirname $0`/prebuilt-common.sh

PROGRAM_PARAMETERS="<src-dir> <ndk-dir> <toolchain>"

PROGRAM_DESCRIPTION=\
"Rebuild the gcc toolchain prebuilt binaries for the Android NDK.

Where <src-dir> is the location of toolchain sources, <ndk-dir> is
the top-level NDK installation path and <toolchain> is the name of
the toolchain to use (e.g. arm-linux-androideabi-4.4.3)."

RELEASE=`date +%Y%m%d`
OUT_DIR=/tmp/ndk-$USER
OPTION_OUT_DIR=
register_option "--out-dir=<path>" do_out_dir "Set temporary build directory" "$OUT_DIR"
do_out_dir() { OPTION_OUT_DIR=$1; }

# Note: platform API level 9 or higher is needed for proper C++ support
OPTION_PLATFORM=
register_var_option "--platform=<name>"  OPTION_PLATFORM "Specify platform name"

OPTION_SYSROOT=
register_var_option "--sysroot=<path>"   OPTION_SYSROOT   "Specify sysroot directory directly"

GDB_VERSION=$(get_default_gdb_version $DEFAULT_GCC_VERSION)
EXPLICIT_GDB_VERSION=
register_option "--gdb-version=<version>" do_gdb_version "Specify gdb version" "$GDB_VERSION"
do_gdb_version () {
    GDB_VERSION=$1
    EXPLICIT_GDB_VERSION=true
}

BINUTILS_VERSION=$(get_default_binutils_version $DEFAULT_GCC_VERSION)
EXPLICIT_BINUTILS_VERSION=
register_option "--binutils-version=<version>" do_binutils_version "Specify binutils version" "$BINUTILS_VERSION"
do_binutils_version () {
    BINUTILS_VERSION=$1
    EXPLICIT_BINUTILS_VERSION=true
}

GMP_VERSION=$(get_default_gmp_version $DEFAULT_GCC_VERSION)
EXPLICIT_GMP_VERSION=
register_option "--gmp-version=<version>" do_gmp_version "Specify gmp version" "$GMP_VERSION"
do_gmp_version () {
    GMP_VERSION=$1
    EXPLICIT_GMP_VERSION=true
}

MPFR_VERSION=$(get_default_mpfr_version $DEFAULT_GCC_VERSION)
EXPLICIT_MPFR_VERSION=
register_option "--mpfr-version=<version>" do_mpfr_version "Specify mpfr version" "$MPFR_VERSION"
do_mpfr_version () {
    MPFR_VERSION=$1
    EXPLICIT_MPFR_VERSION=true
}

MPC_VERSION=$(get_default_mpc_version $DEFAULT_GCC_VERSION)
EXPLICIT_MPC_VERSION=
register_option "--mpc-version=<version>" do_mpc_version "Specify mpc version" "$MPC_VERSION"
do_mpc_version () {
    MPC_VERSION=$1
    EXPLICIT_MPC_VERSION=true
}

EXPAT_VERSION=$(get_default_expat_version $DEFAULT_GCC_VERSION)
EXPLICIT_EXPAT_VERSION=
register_option "--expat-version=<version>" do_expat_version "Specify expat version" "$EXPAT_VERSION"
do_expat_version () {
    EXPAT_VERSION=$1
    EXPLICIT_EXPAT_VERSION=true
}

CLOOG_VERSION=$(get_default_cloog_version $DEFAULT_GCC_VERSION)
EXPLICIT_CLOOG_VERSION=
register_option "--cloog-version=<version>" do_cloog_version "Specify cloog version" "$CLOOG_VERSION"
do_cloog_version () {
    CLOOG_VERSION=$1
    EXPLICIT_CLOOG_VERSION=true
}

PPL_VERSION=$(get_default_ppl_version $DEFAULT_GCC_VERSION)
EXPLICIT_PPL_VERSION=
register_option "--ppl-version=<version>" do_ppl_version "Specify ppl version" "$PPL_VERSION"
do_ppl_version () {
    PPL_VERSION=$1
    EXPLICIT_PPL_VERSION=true
}

CLOOG_VERSION=$DEFAULT_CLOOG_VERSION
register_var_option "--cloog-version=<version>" CLOOG_VERSION "Specify cloog version"

PPL_VERSION=$DEFAULT_PPL_VERSION
register_var_option "--ppl-version=<version>" PPL_VERSION "Specify ppl version"

PACKAGE_DIR=
register_var_option "--package-dir=<path>" PACKAGE_DIR "Create archive tarball in specific directory"

register_mingw_option
register_try64_option
register_jobs_option

extract_parameters "$@"

fix_option OUT_DIR "$OPTION_OUT_DIR" "build directory"
setup_default_log_file $OUT_DIR/build.log
OUT_DIR=$OUT_DIR/host/toolchains

prepare_mingw_toolchain $OUT_DIR

set_parameters ()
{
    SRC_DIR="$1"
    NDK_DIR="$2"
    TOOLCHAIN="$3"

    # Check source directory
    #
    if [ -z "$SRC_DIR" ] ; then
        echo "ERROR: Missing source directory parameter. See --help for details."
        exit 1
    fi

    if [ ! -d "$SRC_DIR/gcc" ] ; then
        echo "ERROR: Source directory does not contain gcc sources: $SRC_DIR"
        exit 1
    fi

    log "Using source directory: $SRC_DIR"

    # Check NDK installation directory
    #
    if [ -z "$NDK_DIR" ] ; then
        echo "ERROR: Missing NDK directory parameter. See --help for details."
        exit 1
    fi

    if [ ! -d "$NDK_DIR" ] ; then
        mkdir -p $NDK_DIR
        if [ $? != 0 ] ; then
            echo "ERROR: Could not create target NDK installation path: $NDK_DIR"
            exit 1
        fi
    fi

    log "Using NDK directory: $NDK_DIR"

    # Check toolchain name
    #
    if [ -z "$TOOLCHAIN" ] ; then
        echo "ERROR: Missing toolchain name parameter. See --help for details."
        exit 1
    fi
}

set_parameters $PARAMETERS

prepare_target_build

parse_toolchain_name $TOOLCHAIN

fix_sysroot "$OPTION_SYSROOT"

check_toolchain_src_dir "$SRC_DIR"

if [ -z "$EXPLICIT_GDB_VERSION" ]; then
    GDB_VERSION=$(get_default_gdb_version $TOOLCHAIN)
    dump "Auto-config: --gdb-version=$GDB_VERSION"
fi

if [ ! -d $SRC_DIR/gdb/gdb-$GDB_VERSION ] ; then
    echo "ERROR: Missing gdb sources: $SRC_DIR/gdb/gdb-$GDB_VERSION"
    echo "       Use --gdb-version=<version> to specify alternative."
    exit 1
fi

if [ -z "$EXPLICIT_BINUTILS_VERSION" ]; then
    BINUTILS_VERSION=$(get_default_binutils_version $TOOLCHAIN)
    dump "Auto-config: --binutils-version=$BINUTILS_VERSION"
fi

if [ ! -d $SRC_DIR/binutils/binutils-$BINUTILS_VERSION ] ; then
    echo "ERROR: Missing binutils sources: $SRC_DIR/binutils/binutils-$BINUTILS_VERSION"
    echo "       Use --binutils-version=<version> to specify alternative."
    exit 1
fi

if [ -z "$EXPLICIT_GMP_VERSION" ]; then
    GMP_VERSION=$(get_default_gmp_version $TOOLCHAIN)
    dump "Auto-config: --gmp-version=$GMP_VERSION"
fi

if [ ! -f $SRC_DIR/gmp/gmp-$GMP_VERSION.tar.bz2 ] ; then
    echo "ERROR: Missing gmp sources: $SRC_DIR/gmp/gmp-$GMP_VERSION.tar.bz2"
    echo "       Use --gmp-version=<version> to specify alternative."
    exit 1
fi

if [ -z "$EXPLICIT_MPFR_VERSION" ]; then
    MPFR_VERSION=$(get_default_mpfr_version $TOOLCHAIN)
    dump "Auto-config: --mpfr-version=$MPFR_VERSION"
fi

if [ ! -f $SRC_DIR/mpfr/mpfr-$MPFR_VERSION.tar.bz2 ] ; then
    echo "ERROR: Missing mpfr sources: $SRC_DIR/mpfr/mpfr-$MPFR_VERSION.tar.bz2"
    echo "       Use --mpfr-version=<version> to specify alternative."
    exit 1
fi

if [ -z "$EXPLICIT_MPC_VERSION" ]; then
    MPC_VERSION=$(get_default_mpc_version $TOOLCHAIN)
    dump "Auto-config: --mpc-version=$MPC_VERSION"
fi

if [ ! -f $SRC_DIR/mpc/mpc-$MPC_VERSION.tar.gz ] ; then
    echo "ERROR: Missing mpc sources: $SRC_DIR/mpc/mpc-$MPC_VERSION.tar.gz"
    echo "       Use --mpc-version=<version> to specify alternative."
    exit 1
fi

if [ -z "$EXPLICIT_EXPAT_VERSION" ]; then
    EXPAT_VERSION=$(get_default_expat_version $TOOLCHAIN)
    dump "Auto-config: --expat-version=$EXPAT_VERSION"
fi

if [ ! -d $SRC_DIR/expat/expat-$EXPAT_VERSION ] ; then
    echo "ERROR: Missing expat sources: $SRC_DIR/expat/expat-$EXPAT_VERSION"
    echo "       Use --expat-version=<version> to specify alternative."
    exit 1
fi

if [ -z "$EXPLICIT_CLOOG_VERSION" ]; then
    CLOOG_VERSION=$(get_default_cloog_version $TOOLCHAIN)
    dump "Auto-config: --cloog-version=$CLOOG_VERSION"
fi

CLOOG_MAJOR_VERSION=$(expr $CLOOG_VERSION : "^\([0-9][0-9]*\)\.")
CLOOG_MINOR_VERSION=$(expr $CLOOG_VERSION : "^[0-9][0-9]*\.\([0-9][0-9]*\)")
if [ $CLOOG_MAJOR_VERSION -eq 0 -a $CLOOG_MINOR_VERSION -le 15 ]; then
    # CLooG/PPL relies on the PPL for version 0.15.x
    CLOOG_PACKAGE=$SRC_DIR/cloog/cloog-ppl-$CLOOG_VERSION.tar.gz
else
    # CLooG 0.16.x has its own embedded polyhedral library
    CLOOG_PACKAGE=$SRC_DIR/cloog/cloog-$CLOOG_VERSION.tar.gz
fi
if [ ! -f $CLOOG_PACKAGE ] ; then
    echo "ERROR: Missing cloog sources: $CLOOG_PACKAGE"
    echo "       Use --cloog-version=<version> to specify alternative."
    exit 1
fi

if [ -z "$EXPLICIT_PPL_VERSION" ]; then
    PPL_VERSION=$(get_default_ppl_version $TOOLCHAIN)
    dump "Auto-config: --ppl-version=$PPL_VERSION"
fi

if [ ! -f $SRC_DIR/ppl/ppl-$PPL_VERSION.tar.bz2 ] ; then
    echo "ERROR: Missing ppl sources: $SRC_DIR/ppl/ppl-$PPL_VERSION.tar.bz2"
    echo "       Use --ppl-version=<version> to specify alternative."
    exit 1
fi

if [ "$PACKAGE_DIR" ]; then
    mkdir -p "$PACKAGE_DIR"
    fail_panic "Could not create package directory: $PACKAGE_DIR"
fi

set_toolchain_ndk $NDK_DIR $TOOLCHAIN

if [ "$MINGW" != "yes" ] ; then
    dump "Using C compiler: $CC"
    dump "Using C++ compiler: $CXX"
fi

OUT_DIR=$OUT_DIR/$TOOLCHAIN-$HOST_TAG
rm -Rf $OUT_DIR
mkdir -p $OUT_DIR

# Location where the toolchain license files are
TOOLCHAIN_LICENSES=$ANDROID_NDK_ROOT/build/tools/toolchain-licenses

# Without option "--sysroot" (and its variations), GCC will attempt to
# search path specified by "--with-sysroot" at build time for headers/libs.
# Path at --with-sysroot contains minimal headers and libs to boostrap
# toolchain build, and it's not needed afterward (NOTE: NDK provides
# sysroot at specified API level,and Android build explicit lists header/lib
# dependencies.
#
# It's better to point --with-sysroot to local directory otherwise the
# path may be found at compile-time and bad things can happen: eg.
#  1) The path exists and contain incorrect headers/libs
#  2) The path exists at remote server and blocks GCC for seconds
#  3) The path exists but not accessible, which crashes GCC!
#
# For canadian build --with-sysroot has to be sub-directory of --prefix.
# Put TOOLCHAIN_BUILD_PREFIX to OUT_DIR which is in /tmp by default,
# and TOOLCHAIN_BUILD_SYSROOT underneath.

TOOLCHAIN_BUILD_PREFIX=$OUT_DIR/prefix
TOOLCHAIN_BUILD_SYSROOT=$TOOLCHAIN_BUILD_PREFIX/sysroot
dump "Sysroot  : Copying: $SYSROOT --> $TOOLCHAIN_BUILD_SYSROOT"
mkdir -p $TOOLCHAIN_BUILD_SYSROOT && (cd $SYSROOT && tar ch *) | (cd $TOOLCHAIN_BUILD_SYSROOT && tar x)
if [ $? != 0 ] ; then
    echo "Error while copying sysroot files. See $TMPLOG"
    exit 1
fi

# currently this is requred only for gcc-4.7/libgomp
dump "Sysroot  : Copying empty libcrystax stubs --> $TOOLCHAIN_BUILD_SYSROOT"
CRYSTAX_SRCDIR=$NDK_DIR/$CRYSTAX_SUBDIR
run mkdir -p "$TOOLCHAIN_BUILD_SYSROOT/usr/lib"
for lib in libcrystax.a libcrystax.so; do
    run cp -f "$CRYSTAX_SRCDIR/empty/$ARCH/$lib" "$TOOLCHAIN_BUILD_SYSROOT/usr/lib/"
    if [ $? != 0 ] ; then
        echo "Error while copying libcrystax stubs. See $TMPLOG"
        exit 1
    fi
done

# configure the toolchain
#
dump "Configure: $TOOLCHAIN toolchain build"
# Old versions of the toolchain source packages placed the
# configure script at the top-level. Newer ones place it under
# the build directory though. Probe the file system to check
# this.
BUILD_SRCDIR=$SRC_DIR/build
if [ ! -d $BUILD_SRCDIR ] ; then
    BUILD_SRCDIR=$SRC_DIR
fi

OLD_ABI="${ABI}"
export CC CXX
export CFLAGS_FOR_TARGET="$ABI_CFLAGS_FOR_TARGET"
export CXXFLAGS_FOR_TARGET="$ABI_CXXFLAGS_FOR_TARGET"
# Needed to build a 32-bit gmp on 64-bit systems
export ABI=$HOST_GMP_ABI
export CFLAGS="$HOST_CFLAGS"
export CXXFLAGS="$HOST_CFLAGS"
export LDFLAGS="$HOST_LDFLAGS"

# -Wno-error is needed because our gdb-6.6 sources use -Werror by default
# and fail to build with recent GCC versions.
export CFLAGS=$CFLAGS" -O2 -s -Wno-error"

# This extra flag is used to slightly speed up the build
EXTRA_CONFIG_FLAGS="--disable-bootstrap"

# This is to disable GCC 4.6 specific features that don't compile well
# the flags are ignored for older GCC versions.
EXTRA_CONFIG_FLAGS=$EXTRA_CONFIG_FLAGS" --disable-libquadmath"
# Plugins are not supported well before 4.7. On 4.7 it's required to have
# -flto working. Flag --enable-plugins (note 's') is actually for binutils,
# this is compiler requirement to have binutils configured this way. Flag
# --disable-plugin is for gcc.
case "$GCC_VERSION" in
    4.4.3|4.6)
        EXTRA_CONFIG_FLAGS=$EXTRA_CONFIG_FLAGS" --disable-plugin"
        ;;
    *)
        EXTRA_CONFIG_FLAGS=$EXTRA_CONFIG_FLAGS" --enable-plugins"
        ;;
esac

# Enable OpenMP
EXTRA_CONFIG_FLAGS=$EXTRA_CONFIG_FLAGS" --enable-libgomp"

# Enable Gold as default
case "$TOOLCHAIN" in
    # Note that only ARM and X86 are supported
    x86-4.[6789]|arm-linux-androideabi-4.[6789])
        EXTRA_CONFIG_FLAGS=$EXTRA_CONFIG_FLAGS" --enable-gold=default"
    ;;
esac

# Enable Graphite
case "$TOOLCHAIN" in
    # Only for 4.6 and 4.7 for now
    *-4.6|*-4.7)
        EXTRA_CONFIG_FLAGS=$EXTRA_CONFIG_FLAGS" --enable-graphite=yes --with-cloog-version=$CLOOG_VERSION --with-ppl-version=$PPL_VERSION"
    ;;
esac

#export LDFLAGS="$HOST_LDFLAGS"
cd $OUT_DIR && run \
$BUILD_SRCDIR/configure --target=$ABI_CONFIGURE_TARGET \
                        --enable-initfini-array \
                        --host=$ABI_CONFIGURE_HOST \
                        --build=$ABI_CONFIGURE_BUILD \
                        --disable-nls \
                        --prefix=$TOOLCHAIN_BUILD_PREFIX \
                        --with-sysroot=$TOOLCHAIN_BUILD_SYSROOT \
                        --with-binutils-version=$BINUTILS_VERSION \
                        --with-mpfr-version=$MPFR_VERSION \
                        --with-mpc-version=$MPC_VERSION \
                        --with-gmp-version=$GMP_VERSION \
                        --with-gcc-version=$GCC_VERSION \
                        --with-gdb-version=$GDB_VERSION \
                        --with-expat-version=$EXPAT_VERSION \
                        --with-gxx-include-dir=$TOOLCHAIN_BUILD_PREFIX/include/c++/$GCC_VERSION \
                        --with-bugurl=$DEFAULT_ISSUE_TRACKER_URL \
                        $EXTRA_CONFIG_FLAGS \
                        $ABI_CONFIGURE_EXTRA_FLAGS
if [ $? != 0 ] ; then
    dump "Error while trying to configure toolchain build. See $TMPLOG"
    exit 1
fi
ABI="$OLD_ABI"
# build the toolchain
dump "Building : $TOOLCHAIN toolchain [this can take a long time]."
cd $OUT_DIR
export CC CXX
export ABI=$HOST_GMP_ABI
JOBS=$NUM_JOBS

while [ -n "1" ]; do
    run make -j$JOBS
    if [ $? = 0 ] ; then
        break
    else
        if [ "$MINGW" = "yes" ] ; then
            # Unfortunately, there is a bug in the GCC build scripts that prevent
            # parallel mingw builds to work properly on some multi-core machines
            # (but not all, sounds like a race condition). Detect this and restart
            # in less parallelism, until -j1 also fail
            JOBS=$((JOBS/2))
            if [ $JOBS -lt 1 ] ; then
                echo "Error while building mingw toolchain. See $TMPLOG"
                exit 1
            fi
            dump "Parallel mingw build failed - continuing in less parallelism -j$JOBS"
        else
            echo "Error while building toolchain. See $TMPLOG"
            exit 1
        fi
    fi
done

ABI="$OLD_ABI"

# install the toolchain to its final location
dump "Install  : $TOOLCHAIN toolchain binaries."
cd $OUT_DIR && run make install
if [ $? != 0 ] ; then
    echo "Error while installing toolchain. See $TMPLOG"
    exit 1
fi

# copy to toolchain path
run copy_directory "$TOOLCHAIN_BUILD_PREFIX" "$TOOLCHAIN_PATH"

if [ "$MINGW" = "yes" ] ; then
    # For some reasons, libraries in $ABI_CONFIGURE_TARGET (*) are not installed.
    # Hack here to copy them over.
    # (*) FYI: libgcc.a and libgcov.a not installed there in the first place
    INSTALL_TARGET_LIB_PATH="$OUT_DIR/host-$ABI_CONFIGURE_BUILD/install/$ABI_CONFIGURE_TARGET/lib"
    TOOLCHAIN_TARGET_LIB_PATH="$TOOLCHAIN_PATH/$ABI_CONFIGURE_TARGET/lib"
    (cd "$INSTALL_TARGET_LIB_PATH" &&
        find . \( -name "*.a" -o -name "*.la" -o -name "*.spec" \) -exec install -D "{}" "$TOOLCHAIN_TARGET_LIB_PATH/{}" \;)
fi

# don't forget to copy the GPL and LGPL license files
run cp -f $TOOLCHAIN_LICENSES/COPYING $TOOLCHAIN_LICENSES/COPYING.LIB $TOOLCHAIN_PATH

# this is required to correctly compile libstdc++ with thread support
case "$GCC_VERSION" in
    4.4.3|4.6)
        GTHR_FILE=$TOOLCHAIN_BUILD_PREFIX/../gcc-$GCC_VERSION/gcc/gthr-default.h
        ;;
    4.7)
        GTHR_FILE=$TOOLCHAIN_BUILD_PREFIX/../gcc-$GCC_VERSION/$ABI_CONFIGURE_TARGET/libgcc/gthr-default.h
        ;;
esac

run cp -f  $GTHR_FILE    $TOOLCHAIN_PATH/lib/gcc/$ABI_CONFIGURE_TARGET/$GCC_VERSION/include/

# remove some unneeded files
run rm -f $TOOLCHAIN_PATH/bin/*-gccbug
run rm -rf $TOOLCHAIN_PATH/info
run rm -rf $TOOLCHAIN_PATH/man
run rm -rf $TOOLCHAIN_PATH/share
run rm -rf $TOOLCHAIN_PATH/lib/gcc/$ABI_CONFIGURE_TARGET/*/install-tools
run rm -rf $TOOLCHAIN_PATH/lib/gcc/$ABI_CONFIGURE_TARGET/*/plugin
run rm -rf $TOOLCHAIN_PATH/libexec/gcc/$ABI_CONFIGURE_TARGET/*/install-tools
run rm -rf $TOOLCHAIN_PATH/lib/libiberty.a
run rm -rf $TOOLCHAIN_PATH/$ABI_CONFIGURE_TARGET/lib/libiberty.a
run rm -rf $TOOLCHAIN_PATH/$ABI_CONFIGURE_TARGET/lib/*/libiberty.a
run rm -rf $TOOLCHAIN_PATH/$ABI_CONFIGURE_TARGET/lib/*/*/libiberty.a
find $TOOLCHAIN_PATH -name "*.la" -exec rm -f {} \;

# Remove libstdc++ for now (will add it differently later)
# We had to build it to get libsupc++ which we keep.
run rm -rf $TOOLCHAIN_PATH/$ABI_CONFIGURE_TARGET/lib/libstdc++.*
run rm -rf $TOOLCHAIN_PATH/$ABI_CONFIGURE_TARGET/lib/*/libstdc++.*
run rm -rf $TOOLCHAIN_PATH/$ABI_CONFIGURE_TARGET/include/c++

# Remove shared libgcc
run rm -rf $(find $TOOLCHAIN_PATH/$ABI_CONFIGURE_TARGET/lib -name 'libgcc_s.*' -print)

# strip binaries to reduce final package size
run strip $TOOLCHAIN_PATH/bin/*
run strip $TOOLCHAIN_PATH/$ABI_CONFIGURE_TARGET/bin/*
run strip $TOOLCHAIN_PATH/libexec/gcc/*/*/cc1$HOST_EXE
run strip $TOOLCHAIN_PATH/libexec/gcc/*/*/cc1plus$HOST_EXE
run strip $TOOLCHAIN_PATH/libexec/gcc/*/*/collect2$HOST_EXE

# copy SOURCES file if present
if [ -f "$SRC_DIR/SOURCES" ]; then
    cp "$SRC_DIR/SOURCES" "$TOOLCHAIN_PATH/SOURCES"
fi

if [ "$PACKAGE_DIR" ]; then
    ARCHIVE="$TOOLCHAIN-$HOST_TAG.tar.bz2"
    SUBDIR=$(get_toolchain_install_subdir $TOOLCHAIN $HOST_TAG)
    dump "Packaging $ARCHIVE"
    pack_archive "$PACKAGE_DIR/$ARCHIVE" "$NDK_DIR" "$SUBDIR"
    fail_panic "Could not package $ABI-$GCC_VERSION toolchain binaries"
fi

dump "Done."
if [ -z "$OPTION_OUT_DIR" ] ; then
    rm -rf $OUT_DIR
fi
