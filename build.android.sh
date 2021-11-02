#!/bin/sh

# ANDROID_NDK_HOME はインストールに応じて変更
export ANDROID_NDK_HOME=~/Library/Android/sdk/ndk/23.0.7599858
export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH 

OPENSSL_VER=1.1.1l
OPENSSL_DIR=openssl-${OPENSSL_VER}
OPENSSL_FILE=openssl-${OPENSSL_VER}.tar.gz

if [ ! -f ${OPENSSL_FILE} ]; then
  curl -L https://www.openssl.org/source/${OPENSSL_FILE} > ${OPENSSL_FILE}
fi

if [ ! -e ${OPENSSL_DIR} ]; then
    tar xvfz ${OPENSSL_FILE}
fi

function androidBuildOne {
    APIVER=$1
    ARCH=$2
    CONFARCH=$3

    make clean
    ./Configure reconfigure

    ./Configure $CONFARCH \
        --cross-compile-prefix=$ARCH-linux-androideabi$APIVER \
        -D__ANDROID_API__=$APIVER \
        CC=clang \
        no-shared \
        no-tests

    make

    if [ ! -e ./dist/$ARCH ]; then
        mkdir -p ./dist/$ARCH
    fi
    cp libcrypto.a ./dist/$ARCH
    cp libssl.a    ./dist/$ARCH
}

function androidBuild {
    pushd $OPENSSL_DIR

    if [ -e ./dist ]; then
        rm -rf ./dist
    fi

    androidBuildOne 26 armeabi-v7a android-arm
    androidBuildOne 26 x86_64      android-x86_64
    androidBuildOne 26 x86         android-x86
    androidBuildOne 26 arm64-v8a   android-arm64

    popd

    OPENSSL_LIBS="libs.android.${OPENSSL_VER}"

    if [ -e ${OPENSSL_LIBS} ]; then
        rm -rf ${OPENSSL_LIBS}
    fi
    mkdir -p ${OPENSSL_LIBS}/lib
    mkdir -p ${OPENSSL_LIBS}/include/openssl

    cp -r ${OPENSSL_DIR}/dist/* ${OPENSSL_LIBS}/lib

    cp -r ${OPENSSL_DIR}/include/openssl ${OPENSSL_LIBS}/include

    tar cvfz ${OPENSSL_LIBS}.tar.gz ${OPENSSL_LIBS}
}

androidBuild