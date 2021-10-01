#!/bin/sh

XCODE_PATH=`xcode-select --print-path`

OPENSSL_VER=1.1.1l
OPENSSL_DIR=openssl-${OPENSSL_VER}
OPENSSL_FILE=openssl-${OPENSSL_VER}.tar.gz

if [ ! -f ${OPENSSL_FILE} ]; then
  curl -L https://www.openssl.org/source/${OPENSSL_FILE} > ${OPENSSL_FILE}
fi

if [ ! -e ${OPENSSL_DIR} ]; then
    tar xvfz ${OPENSSL_FILE}
fi

function iosBuildOne {
    ARCH=$1
    CONFARCH=$2
    OS=$3

    make clean
    ./Configure reconfigure

    ./Configure $CONFARCH \
        no-shared \
        no-tests \
        no-ui \
        no-stdio

    export CROSS_COMPILE="${XCODE_PATH}/Toolchains/XcodeDefault.xctoolchain/usr/bin/"
    export CROSS_TOP="${XCODE_PATH}/Platforms/${OS}.platform/Developer"
    export CROSS_SDK=${OS}.sdk
    make

    if [ ! -e ./dist/$ARCH ]; then
        mkdir -p ./dist/$ARCH
    fi
    cp libcrypto.a ./dist/$ARCH
    cp libssl.a    ./dist/$ARCH
}


function iosBuild {
    pushd $OPENSSL_DIR

    if [ -e ./dist ]; then
        rm -rf ./dist
    fi

    iosBuildOne armv7s ios-cross iPhoneOS
    iosBuildOne x86_64 "-mios-simulator-version-min=9.0 iphoneos-cross" iPhoneSimulator
    iosBuildOne arm64  ios64-cross iPhoneOS

    popd

    OPENSSL_LIBS="libs.ios.${OPENSSL_VER}"

    if [ -e ${OPENSSL_LIBS} ]; then
        rm -rf ${OPENSSL_LIBS}
    fi
    mkdir -p ${OPENSSL_LIBS}/lib
    mkdir -p ${OPENSSL_LIBS}/include

    lipo -create \
        ${OPENSSL_DIR}/dist/arm64/libcrypto.a \
        ${OPENSSL_DIR}/dist/armv7s/libcrypto.a \
        ${OPENSSL_DIR}/dist/x86_64/libcrypto.a \
        -output ${OPENSSL_LIBS}/lib/libcrypto.a

    lipo -create \
        ${OPENSSL_DIR}/dist/arm64/libssl.a \
        ${OPENSSL_DIR}/dist/armv7s/libssl.a \
        ${OPENSSL_DIR}/dist/x86_64/libssl.a \
        -output ${OPENSSL_LIBS}/lib/libssl.a

    cp -r ${OPENSSL_DIR}/include/openssl ${OPENSSL_LIBS}/include

    tar cvfz ${OPENSSL_LIBS}.tar.gz ${OPENSSL_LIBS}
}

iosBuild

