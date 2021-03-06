#!/bin/bash -e

. opts.sh
setvars=../../stub/setvars.sh
export STUBDIR=$(pwd)

echo "Now this script will download and build some libraries using plain http..."
read -p"Press ENTER..." unused

function build_stub()
{
	test -f stub.built && return
	test -d stub || cp -a "$STUBDIR" stub
	pushd stub
	$MAKERUNNER $setvars make
	popd
	touch stub.built
}

function build_libffi()
{
    test -f libffi.built && return
    test -d libffi || git clone --depth 1 --branch emscripten https://github.com/atrosinenko/libffi.git
    pushd libffi
    test -f configure || ./autogen.sh
    $CONFRUNNER $setvars ./configure $FFIOPT
    $MAKERUNNER make
    popd
    touch libffi.built
}

function build_zlib()
{
    ZLIB_VER="1.2.11"
    test -f zlib.built && return
    test -d zlib || wget http://zlib.net/zlib-$ZLIB_VER.tar.gz
    test -d zlib || tar -axf zlib-$ZLIB_VER.tar.gz
    mv zlib-$ZLIB_VER zlib
    pushd zlib
    $CONFRUNNER $setvars ./configure
    $MAKERUNNER make
    popd
    touch zlib.built
}

function build_gettext()
{
    test -f gettext.built && return
    test -d gettext-0.19 || wget http://ftp.gnu.org/pub/gnu/gettext/gettext-0.19.tar.gz
    test -d gettext-0.19 || tar -axf gettext-0.19.tar.gz
    pushd gettext-0.19/gettext-runtime
    $CONFRUNNER ../$setvars ./configure  --disable-java --disable-native-java --disable-threads --disable-acl --disable-openmp --disable-curses
    $MAKERUNNER make
    popd
    touch gettext.built
}

function build_glib()
{
    test -f glib.built && return
    test -d glib || git clone --depth 1 --branch emscripten https://github.com/atrosinenko/glib.git
    pushd glib

    curdir=$(pwd)
    export ZLIB_CFLAGS=-I${curdir}/../zlib-1.2.8
    export ZLIB_LIBS=-lz
    export LIBFFI_CFLAGS=-I${curdir}/../libffi/*-gnu/include
    export LIBFFI_LIBS=-lffi
    export LIBS="-L${curdir}/../gettext-0.19/gettext-runtime/intl/.libs/ -L${curdir}/../stub/"
    
    test -f ./configure || NOCONFIGURE=1 $setvars ./autogen.sh
    $CONFRUNNER $setvars ./configure --disable-always-build-tests --with-pcre=internal
    $MAKERUNNER make || true # Work around for trying to run tests that are non-executable
    popd
    touch glib.built
}

function build_pixman()
{
    test -f pixman.built && return
    test -d pixman-0.32.6 || wget http://cairographics.org/releases/pixman-0.32.6.tar.gz
    test -d pixman-0.32.6 || tar -axf pixman-0.32.6.tar.gz
    pushd pixman-0.32.6
    $CONFRUNNER $setvars ./configure
    $MAKERUNNER make -C pixman
    popd
    touch pixman.built
}

mkdir -p ../$DIRNAME
cd ../$DIRNAME
build_stub
build_libffi
build_zlib
build_gettext
build_glib
build_pixman

