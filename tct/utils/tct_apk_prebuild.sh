#!/usr/bin/env bash

# 过滤不进行编译的项目或分支
function filter() {

    case ${project_name} in
        sm7250-r0-seattletmo-dint) # seattletmo R
            case ${GERRIT_PROJECT} in
                genericapp/gcs_HiddenMenu)
                    case ${GERRIT_BRANCH} in
                        Gcs_HiddenMenu_Common_mtk)
                            echo true
                        ;;

                        *)
                            echo false
                        ;;
                    esac
                ;;

                *)
                    echo false
                ;;
            esac
        ;;

        sm6125-r0-portotmo-dint) # portotmo R
            case ${GERRIT_PROJECT} in
                genericapp/gcs_HiddenMenu)
                    case ${GERRIT_BRANCH} in
                        Gcs_HiddenMenu_Common_mtk)
                            echo true
                        ;;

                        *)
                            echo false
                        ;;
                    esac
                ;;

                *)
                    echo false
                ;;
            esac
        ;;

        mt6762-tf-r0-v1.1-dint) # Tokyo Lite TMO R
            case ${GERRIT_PROJECT} in
                genericapp/gcs_HiddenMenu)
                    case ${GERRIT_BRANCH} in
                        Gcs_HiddenMenu_Common)
                            echo true
                        ;;

                        *)
                            echo false
                        ;;
                    esac
                ;;

                *)
                    echo false
                ;;
            esac
            ;;

        *)
            echo false
        ;;
    esac
}