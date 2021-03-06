#!/bin/bash

# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Script to fetch latest swagger spec.
# Puts the updated spec at api/swagger-spec/

set -o errexit
set -o nounset
set -o pipefail

ARGC=$#

if [ $# -ne 2 ]; then
    echo "Usage:"
    echo "    csharp.sh OUTPUT_DIR SETTING_FILE_PATH"
    echo "    Setting file should define KUBERNETES_BRANCH, CLIENT_VERSION, and PACKAGE_NAME"
    exit 1
fi


OUTPUT_DIR=$1
SETTING_FILE=$2
mkdir -p "${OUTPUT_DIR}"

SCRIPT_ROOT=$(dirname "${BASH_SOURCE}")
pushd "${SCRIPT_ROOT}" > /dev/null
SCRIPT_ROOT=`pwd`
popd > /dev/null

pushd "${OUTPUT_DIR}" > /dev/null
OUTPUT_DIR=`pwd`
popd > /dev/null

source "${SCRIPT_ROOT}/client-generator.sh"
source "${SETTING_FILE}"

# this is to ensure sed after docker build has perm to modify files generated
mkdir -p ${OUTPUT_DIR}/Models/

# TODO(brendandburns): Update CLEANUP_DIRS
CLIENT_LANGUAGE=csharp; CLEANUP_DIRS=(docs src target gradle); kubeclient::generator::generate_client "${OUTPUT_DIR}"

# hack for generating empty host url
sed -i '/BaseUri = new System.Uri(\"\");/ d' ${OUTPUT_DIR}/Kubernetes.cs

# remove public prop from Quantity, (autorest cannot generate empty class)
sed -i '/JsonProperty/ d' ${OUTPUT_DIR}/Models/ResourceQuantity.cs
sed -i 's/public string Value/private string Value/' ${OUTPUT_DIR}/Models/ResourceQuantity.cs
