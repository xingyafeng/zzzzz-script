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

        mt6761-r0-tokyolitetmo-dint) # Tokyo Lite TMO R
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

                genericapp/gcs_SystemUI)
                    case ${GERRIT_BRANCH} in
                        gcs_SystemUI_common)
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