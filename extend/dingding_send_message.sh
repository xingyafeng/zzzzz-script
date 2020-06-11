#!/usr/bin/env bash

# TODO 临时的、短期解决方案的、或者足够好但不够完美的代码

## 钉钉通知
function dingding_send_to_message() {

    local type=$1
    local robot=""
    local msg=""

    # 机器人类型
    case ${type} in

        # 听风小分队 #用户吐槽信息通知
        1)
            robot="https://oapi.dingtalk.com/robot/send?access_token=9d36ccaf568faed3ba2dd3f0b5cdba1863c6fa567422ea36d0f3bf35eb8bd18e"
            ;;

        *)
            :
            ;;
    esac

    # 发送消息
    if [[ -n "$2" ]]; then
        msg=$2
    fi

    if [[ "$#" -ne 2 ]]; then
        log error "参数不正确 ..."
    fi

if false;then
    ## 文本消息
    curl  "${robot}" -H 'Content-Type: application/json' -d "
    { \"msgtype\": \"text\",
        \"text\": {
            \"content\": \"我就是我,@188xxx  是不一样的烟e火,  eee \"
        },
      \"at\":{
            \"atMobiles\":[
                \"18566789612\"
            ],
            \"isAtAll\":false
      }
    }"

    ## 卡片消息
    curl "${robot}" -H 'Content-Type: application/json' -d "
    {
        \"actionCard\": {
            \"title\": \"$2\",
            \"text\": \"$3\",
            \"hideAvatar\": \"0\",
            \"btnOrientation\": \"0\",
            \"btns\": [
                {
                    \"title\": \"$2\",
                    \"actionURL\": \"\"
                }
            ]
        },
        \"msgtype\": \"actionCard\"
    }"


    ## 语音消息
    curl "${robot}" -H 'Content-Type: application/json' -d "
    {
        \"msgtype\": \"voice\",
            \"voice\": {
                \"media_id\": \"MEDIA_ID\",
            \"duration\": \"60\"
            }
    }"
fi

    ## link
    curl "${robot}" -H 'Content-Type: application/json' -d "
    {
        \"msgtype\": \"link\",
        \"link\": {
            \"text\":\"群机器人是钉钉群的高级扩展功能。群机器人可以将第三方服务的信息聚合到群聊中，实现自动化的信息同步。例如：通过聚合GitHub，GitLab等源码管理服务，实现源码更新同步；通过聚合Trello，JIRA等项目协调服务，实现项目信息同步。不仅如此，群机器人支持Webhook协议的自定义接入，支持更多可能性，例如：你可将运维报警提醒通过自定义机器人聚合到钉钉群。\",
            \"title\": \"自定义机器人协议\",
            \"picUrl\": \"\",
            \"messageUrl\": \"${msg}\"
        }
    }"
}