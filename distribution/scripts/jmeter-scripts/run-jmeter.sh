#!/bin/bash
# Copyright 2017 WSO2 Inc. (http://wso2.org)
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
# Run Performance Tests for Ballerina
# ----------------------------------------------------------------------------

if [[ -d results ]]; then
    echo "Results directory already exists"
    exit 1
fi

jmeter_dir=""
for dir in $HOME/apache-jmeter*; do
    [ -d "${dir}" ] && jmeter_dir="${dir}" && break
done
export JMETER_HOME="${jmeter_dir}"
export PATH=$JMETER_HOME/bin:$PATH

message_size=(50 1024 10240 102400)
concurrent_users=(1 50 100 500 1000)
ballerina_files=("helloworld.bal" "transformation.bal" "passthrough.bal")
ballerina_flags=("\ " "--observe" "-e\ b7a.observability.tracing.enabled=true" "-e\ b7a.observability.metrics.enabled=true")
ballerina_heap_size=(1G 25M)

ballerina_host=10.42.0.6
api_path=/HelloWorld/sayHello
ballerina_ssh_host=ballerina

# Test Duration in seconds
test_duration=900

# Warm-up time in minutes
warmup_time=5

mkdir results
cp $0 results

$HOME/payloads/generate-payloads.sh

write_server_metrics() {
    server=$1
    ssh_host=$2
    pgrep_pattern=$3
    command_prefix=""
    if [[ ! -z $ssh_host ]]; then
        command_prefix="ssh $ssh_host"
    fi
    $command_prefix ss -s > ${report_location}/${server}_ss.txt
    $command_prefix uptime > ${report_location}/${server}_uptime.txt
    $command_prefix sar -q > ${report_location}/${server}_loadavg.txt
    $command_prefix sar -A > ${report_location}/${server}_sar.txt
    $command_prefix top -bn 1 > ${report_location}/${server}_top.txt
    if [[ ! -z $pgrep_pattern ]]; then
        $command_prefix ps u -p \`pgrep -f $pgrep_pattern\` > ${report_location}/${server}_ps.txt
    fi
}

for heap in ${ballerina_heap_size[@]}
do
    for bal_file in ${ballerina_files[@]}
    do
        if [[ ${bal_file} == "helloworld.bal" ]]; then
            echo "Hello World file executing hence only one message size"
            message_size=(50)
        fi
        for bal_flags in "${ballerina_flags[@]}"
        do
            for u in ${concurrent_users[@]}
            do
                for msize in ${message_size[@]}
                do
                    report_location=$PWD/results/${msize}B/${u}_users/$bal_file/"${bal_flags//[[:space:]]/}"_flags/$heap_heap
                    echo "Report location is ${report_location}"
                    mkdir -p $report_location

                    echo "Starting ballerina Service"
                    ssh $ballerina_ssh_host "./ballerina-scripts/ballerina-start.sh $heap $bal_file $bal_flags"

                    echo "Starting Jmeter server"

                    export JVM_ARGS="-Xms2g -Xmx2g -XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:$report_location/jmeter_gc.log"
                    echo "# Running JMeter. Concurrent Users: $u Duration: $test_duration JVM Args: $JVM_ARGS" Ballerina host: $ballerina_host Path: $api_path Flags: $bal_flags

                    if [[ ${bal_file} == "helloworld.bal" ]]; then
                        echo "Using get request jmx"
                        jmeter -n -t $HOME/jmeter-scripts/get-request-test.jmx \
                            -Jusers=$u -Jduration=$test_duration -Jhost=$ballerina_host -Jport=9090 -Jpath=$api_path \
                            -Jprotocol=http -l ${report_location}/results.jtl
                    else
                        echo "Using post request jmx"
                        jmeter -n -t $HOME/jmeter-scripts/post-request-test.jmx \
                            -Jusers=$u -Jduration=$test_duration -Jhost=$ballerina_host -Jport=9090 -Jpath=$api_path \
                            -Jpayload=$HOME/${msize}B.json -Jresponse_size=${msize}B \
                            -Jprotocol=http -l ${report_location}/results.jtl
                    fi



                    echo "Writing Server Metrics"
                    write_server_metrics jmeter
                    write_server_metrics ballerina $ballerina_ssh_host ballerina/bre

                    $HOME/jtl-splitter/jtl-splitter.sh ${report_location}/results.jtl $warmup_time
                    echo "Generating Dashboard for Warmup Period"
                    jmeter -g ${report_location}/results-warmup.jtl -o $report_location/dashboard-warmup
                    echo "Generating Dashboard for Measurement Period"
                    jmeter -g ${report_location}/results-measurement.jtl -o $report_location/dashboard-measurement

                    echo "Zipping JTL files in ${report_location}"
                    zip -jm ${report_location}/jtls.zip ${report_location}/results*.jtl

                    scp $ballerina_ssh_host:ballerina/logs/ballerina.log ${report_location}/ballerina.log
                 done
            done
        done
    done
done

echo "Completed"