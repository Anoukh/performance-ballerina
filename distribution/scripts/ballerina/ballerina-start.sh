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
# Start Ballerina Service
# ----------------------------------------------------------------------------

# Required parameters -> heap size, ballerina file


heap_size=$1
if [[ -z $heap_size ]]; then
    heap_size="1G"
fi

bal_file=$2
if [[ -z $bal_file ]]; then
    bal_file="helloworld.bal"
fi

jvm_dir=""
for dir in /usr/lib/jvm/jdk1.8*; do
    [ -d "${dir}" ] && jvm_dir="${dir}" && break
done
export JAVA_HOME="${jvm_dir}"

log_files=(${ballerina_path}/logs/*)
if [ ${#log_files[@]} -gt 1 ]; then
    echo "Log files exists. Moving to /tmp/${bal_file}"
    mv ${ballerina_path}/logs/* /tmp/${bal_file};
fi

echo "Setting Heap to ${heap_size}"
export JVM_MEM_OPTS="-Xms${heap_size} -Xmx${heap_size}"

echo "Enabling GC Logs"
export JAVA_OPTS="-XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:${ballerina_path}/logs/${bal_file}/gc.log"

echo "Starting Ballerina Service"
nohup ${ballerina_path}/bin/ballerina run ${bal_file} &>> ${ballerina_path}/logs/${bal_file}/ballerina.log&

echo "Waiting for Ballerina Service to start"

while true
do
    # Check Version service
    response_code="$(curl -sk -w "%{http_code}" -o /dev/null https://localhost:9090/HelloWorld/sayHello)"
    if [ $response_code -eq 200 ]; then
        echo "Ballerina Service started ${bal_file}"
        break
    else
        sleep 10
    fi
done

# Wait for another 10 seconds to make sure that the server is ready to accept API requests.
sleep 10