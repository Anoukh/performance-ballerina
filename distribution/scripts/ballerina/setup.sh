#!/bin/bash
# Copyright 2018 WSO2 Inc. (http://wso2.org)
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
#
# ----------------------------------------------------------------------------
# Setup Ballerina Distro
# ----------------------------------------------------------------------------

# This script will run all other scripts to configure and setup Ballerina Distro

script_dir=$(dirname "$0")

ballerina_version="ballerina-0.970.0-beta2-SNAPSHOT"
ballerina_path="$HOME/${ballerina_version}"

# Extract Ballerina Distro
if [[ ! -f $ballerina_path.zip ]]; then
    echo "Please download Ballerina to $HOME"
    exit 1
fi
if [[ ! -d $ballerina_path ]]; then
    echo "Extracting Ballerina Distro"
    unzip -q $ballerina_path.zip -d $HOME
    echo "Ballerina Distro is extracted"
else
    echo "Ballerina Distro is already extracted"
    exit 1
fi

cp $script_dir/bal/helloworld.bal $ballerina_path/bin
cp $script_dir/bal/process-intesive.bal $ballerina_path/bin
