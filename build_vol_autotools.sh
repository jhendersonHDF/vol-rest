#!/bin/sh
#
# Copyright by The HDF Group.                                              
# All rights reserved.                                                     
#
# This file is part of HDF5. The full HDF5 copyright notice, including     
# terms governing use, modification, and redistribution, is contained in   
# the files COPYING and Copyright.html.  COPYING can be found at the root  
# of the source code distribution tree; Copyright.html can be found at the 
# root level of an installed copy of the electronic document set and is    
# linked from the top-level documents page.  It can also be found at       
# http://hdfgroup.org/HDF5/doc/Copyright.html.  If you do not have access  
# to either file, you may request a copy from help@hdfgroup.org.           
#
# A script used to first configure and build the HDF5 source distribution
# included with the REST VOL plugin source code, and then use that built
# HDF5 to build the REST VOL plugin itself.

# Get the directory of the script itself
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set the default install directory
INSTALL_DIR="${SCRIPT_DIR}/rest_vol_build"

# Default name of the directory for the included HDF5 source distribution,
# as well as the default directory where it gets installed
HDF5_DIR="hdf5"
HDF5_INSTALL_DIR="${INSTALL_DIR}"
build_hdf5=true

# Determine the number of processors to use when
# building in parallel with Autotools make
NPROCS=0

# Default is to not build tools due to circular dependency on VOL being
# already built
build_tools=false

# Compiler flags for linking with cURL and YAJL
CURL_DIR=""
CURL_LINK="-lcurl"
YAJL_DIR=""
YAJL_LINK="-lyajl"

# Compiler flag for linking with the built REST VOL
REST_VOL_LINK="-lrestvol"

# Extra compiler options passed to the various steps, such as -Wall
COMP_OPTS="-Wall -pedantic -Wunused-macros"

# Extra options passed to the REST VOLs configure script
RV_OPTS=""


echo
echo "*************************"
echo "* REST VOL build script *"
echo "*************************"
echo

usage()
{
    echo "usage: $0 [OPTIONS]"
    echo
    echo "      -h      Print this help message."
    echo
    echo "      -d      Enable debugging output in the REST VOL."
    echo
    echo "      -c      Enable cURL debugging output in the REST VOL."
    echo
    echo "      -m      Enable memory tracking in the REST VOL."
    echo
    echo "      -t      Build the tools with REST VOL support. Note"
    echo "              that due to a circular build dependency, this"
    echo "              option should not be chosen until after the"
    echo "              included HDF5 source distribution and the"
    echo "              REST VOL plugin have been built once."
    echo
    echo "      -P DIR  Similar to 'configure --prefix=DIR', specifies"
    echo "              where the REST VOL should be installed to. Default"
    echo "              is 'source directory/rest_vol_build'."
    echo
    echo "      -H DIR  To specify a directory where HDF5 has already"
    echo "              been built."
    echo
    echo "      -C DIR  To specify the top-level directory where cURL is"
    echo "              installed, if cURL was not installed to a system"
    echo "              directory."
    echo
    echo "      -Y DIR  To specify the top-level directory where YAJL is"
    echo "              installed, if YAJL was not installed to a system"
    echo "              directory."
    echo
}

optspec=":hctdmH:C:Y:P:-"
while getopts "$optspec" optchar; do
    case "${optchar}" in
    h)
        usage
        exit 0
        ;;
    d)
        RV_OPTS="${RV_OPTS} --enable-build-mode=debug"
        echo "Enabled plugin debugging"
        echo
        ;;
    c)
        RV_OPTS="${RV_OPTS} --enable-curl-debug"
        echo "Enabled cURL debugging"
        echo
        ;;
    m)
        RV_OPTS="${RV_OPTS} --enable-mem-tracking"
        echo "Enabled plugin memory tracking"
        echo
        ;;
    t)
        build_tools=true
        echo "Building tools with REST VOL support"
        echo
        ;;
    P)
        if [ "$HDF5_INSTALL_DIR" = "$INSTALL_DIR" ]; then
            HDF5_INSTALL_DIR="$OPTARG"
            echo "Set HDF5 install directory to: ${HDF5_INSTALL_DIR}"
        fi

        INSTALL_DIR="$OPTARG"
        echo "Prefix set to: ${INSTALL_DIR}"
        echo
        ;;
    H)
        build_hdf5=false
        HDF5_INSTALL_DIR="$OPTARG"
        RV_OPTS="${RV_OPTS} --with-hdf5=${HDF5_INSTALL_DIR}"
        echo "Set HDF5 install directory to: ${HDF5_INSTALL_DIR}"
        echo
        ;;
    C)
        CURL_DIR="$OPTARG"
        CURL_LINK="-L${CURL_DIR}/lib ${CURL_LINK}"
        RV_OPTS="${RV_OPTS} --with-curl=${CURL_DIR}"
        echo "Libcurl directory set to: ${CURL_DIR}"
        echo
        ;;
    Y)
        YAJL_DIR="$OPTARG"
        YAJL_LINK="-L${YAJL_DIR}/lib ${YAJL_LINK}"
        RV_OPTS="${RV_OPTS} --with-yajl=${YAJL_DIR}"
        echo "Libyajl directory set to: ${YAJL_DIR}"
        echo
        ;;
    *)
        if [ "$OPTERR" != 1 ] || case $optspec in :*) ;; *) false; esac; then
            echo "ERROR: non-option argument: '-${OPTARG}'" >&2
            echo
            usage
            echo
            exit 1
        fi
        ;;
    esac
done


# Try to determine a good number of cores to use for parallelizing both builds
if [ "$NPROCS" -eq "0" ]; then
    NPROCS=`getconf _NPROCESSORS_ONLN 2> /dev/null`

    # Handle FreeBSD
    if [ -z "$NPROCS" ]; then
        NPROCS=`getconf NPROCESSORS_ONLN 2> /dev/null`
    fi
fi


# If the user hasn't already, first build HDF5
if [ "$build_hdf5" = true ]; then
    echo "*****************"
    echo "* Building HDF5 *"
    echo "*****************"
    echo

    cd "${SCRIPT_DIR}/${HDF5_DIR}"

    ./autogen.sh || exit 1

    # If we are building the tools with REST VOL support, link in the already built
    # REST VOL library, along with cURL and YAJL.
    if [ "${build_tools}" = true ]; then
        ./configure --prefix="${HDF5_INSTALL_DIR}" CFLAGS="${COMP_OPTS} -L${INSTALL_DIR}/lib ${REST_VOL_LINK} ${CURL_LINK} ${YAJL_LINK}" || exit 1
    else
        ./configure --prefix="${HDF5_INSTALL_DIR}" CFLAGS="${COMP_OPTS}" || exit 1
    fi

    make -j${NPROCS} && make install || exit 1

    # If building the tools with REST VOL support, don't rebuild the REST VOL
    if [ "${build_tools}" = true ]; then
        exit 0
    fi
fi


# Once HDF5 has been built, build the REST VOL plugin against HDF5.
echo "*******************************************"
echo "* Building REST VOL plugin and test suite *"
echo "*******************************************"
echo

mkdir -p "${INSTALL_DIR}"

cd "${SCRIPT_DIR}"

./autogen.sh || exit 1

./configure --prefix="${INSTALL_DIR}" ${RV_OPTS} CFLAGS="${COMP_OPTS}" || exit 1

make -j${NPROCS} && make install || exit 1

exit 0
