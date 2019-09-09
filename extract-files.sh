#!/bin/bash
#
# Copyright (C) 2018 The LineageOS Project
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

set -e

DEVICE=X00T
VENDOR=asus

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

SYBERIA_ROOT="$MY_DIR"/../../..

HELPER="$SYBERIA_ROOT"/vendor/syberia/build/tools/extract_utils.sh
if [ ! -f "$HELPER" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
. "$HELPER"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

while [ "$1" != "" ]; do
    case $1 in
        -n | --no-cleanup )     CLEAN_VENDOR=false
                                ;;
        -s | --section )        shift
                                SECTION=$1
                                CLEAN_VENDOR=false
                                ;;
        * )                     SRC=$1
                                ;;
    esac
    shift
done

if [ -z "$SRC" ]; then
    SRC=adb
fi

# Initialize the helper
setup_vendor "$DEVICE" "$VENDOR" "$SYBERIA_ROOT" false "$CLEAN_VENDOR"

extract "$MY_DIR"/proprietary-files.txt "$SRC" "$SECTION"

# Load vndk-28 libui for libmot_gpu_mapper
MOT_GPU_MAPPER="$BLOB_ROOT"/vendor/lib/libmot_gpu_mapper.so
patchelf --add-needed libui-v28.so "$MOT_GPU_MAPPER"

. "$MY_DIR"/setup-makefiles.sh

patchelf --replace-needed "libicuuc.so" "libicuuq.so" "$DEVICE_BLOB_ROOT"/vendor/lib/libMiWatermark.so
patchelf --replace-needed "libminikin.so" "libminiq.so" "$DEVICE_BLOB_ROOT"/vendor/lib/libMiWatermark.so
patchelf --set-soname "libicuuq.so" "$DEVICE_BLOB_ROOT"/vendor/lib/libicuuc.so
patchelf --set-soname "libminiq.so" "$DEVICE_BLOB_ROOT"/vendor/lib/libminikin.so

# Load camera.sdm660.so shim
CAM_SDM660="$DEVICE_BLOB_ROOT"/vendor/lib/hw/camera.sdm660.so
patchelf --add-needed camera.sdm660_shim.so "$CAM_SDM660"
