#!/usr/bin/env bash

function command() {
    command="$@"

    echo
    echo '@@@@@'
    __green__ "cmd: \$ $command"
    echo '@@@@@'
    echo

    eval ${command}
    if [[ $? -ne 0 ]]; then
        log error  "FAILED: $command"
    fi
}

# 检查路径是否存在, -d
function check_if_dir_exists() {

    if [[ ! -d "$1" ]]; then
        log error "Could not find the dir: \"$1\", aborting ..."
    fi
}

# 检查文件是否存在， -f
function check_if_file_exists() {

    if [[ ! -f "$1" ]]; then
        log error "Could not find the file: \"$1\", aborting ..."
    fi
}