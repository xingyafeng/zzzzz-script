#!/usr/bin/env bash

## 是否由zenportal启动
function is_zen_start()
{
    case ${BUILD_USER_ID} in

        zenportal)
            echo true
        ;;

        *)
            echo false
        ;;
    esac
}

## 是否为Zen平台项目
function is_zen_project()
{
    case ${JOB_NAME} in

        k21)
            echo true
            ;;

        mk01|mk21|mk26|mk28)
            echo true
            ;;

        cm01|cm02|ck02|ck03|ck05|ck06)
            echo true
            ;;

        cs01)
            echo true
            ;;

        ms16|ms18)
            echo true
            ;;

        k68c)
            echo true
            ;;

         OTA|OTA_develop)
            echo true
            ;;

         rom_release|rom_release_develop)
            echo true
            ;;

        *)
            case ${yunovo_board} in

                k21)
                    echo true
                    ;;

                mk01|mk21|mk26|mk28)
                    echo true
                    ;;

                cm01|cm02|ck02|ck03|ck05|ck06)
                    echo true
                    ;;

                cs01)
                    echo true
                    ;;

                ms16|ms18)
                    echo true
                    ;;

                k68c)
                    echo true
                    ;;

                *)
                    echo false
                    ;;
            esac
            ;;
    esac
}

# 是否为app zenchain项目
function is_app_zenchain() {

    case ${JOB_NAME} in

        nxBt|nxFM|nxOTA|nxPAL|nxLogDog|nxTraffic|nxWeather|nxDataWare|nxRecorder|nxSettings)
            echo true
            ;;

        nxSystemUI|nxDogRobber|nxCarService|nxJPushAdapter|nxDataCollector|nxTrafficService)
            echo true
            ;;

        nxLiteNaviLauncher|nxPlatformService|nxSettingsProvider)
            echo true
            ;;

        *)
            echo true
            ;;
    esac
}

## 是否为云智主分支项目
function is_main_branch()
{
    case `get_project_real_name` in

        k21_stable)
            echo true
            ;;

        k20_master|k21_master|k26_master|k26s_master|k27_master|k28s_master|mk26_master)
            echo true
            ;;

        mk01_master)
            echo true
            ;;

        mk26_stable)
            echo true
            ;;

        k88c_master|k89_master|mx1_master)
            echo true
            ;;

        k89_yxf7_kd001)
            echo true
            ;;

        k85_master|k86s-mx17_master|k68c_master|k897_master|k88c7_baseline|k86s-mx17_bsp4ali)
            echo true
            ;;

        k68_master|k68_baseline)
            echo true
            ;;

        k68c_bsp4ali|k68c_dh_cyt01)
            echo true
            ;;

        k86s_netop_develop|k88d_baseline)
            echo true
            ;;

        ## k60版型 MT6737T
        k60_master|k60_carrobot_develop|k60_carrobot_s1|k60_baseline)
            echo true
            ;;

        ## k61版型 MT6737T
        k61_master)
            echo true
            ;;

        k26s1_vst_k7s) ## 分支构建
            echo true
            ;;

        k68d_master) ## k68版型
            echo true
            ;;

        k26s1_zm01s|c2m_master)
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

# 是否为CTA项目
function is_cta_project() {

    case `get_project_real_name` in

        k88c_cta)
            echo true
            ;;

        k68c_cta|k68c_ctadebug|k68c_hs_c3-cta|k68c_cz_at1202-cta)
            echo true
            ;;

        ck02_oreo_cta)
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

## 是否为展讯项目
function is_sc_project()
{
    case `get_project_real_name` in

        tg88_master|ms16_master|ms18_master)
            echo true
            ;;

        cs01_master)
            echo true
            ;;

        *)
            case ${JOB_NAME} in
                ms16|ms18|cs01)
                    echo true
                    ;;

                *)
                    case ${yunovo_board} in
                        ms16|ms18|cs01)
                            echo true
                        ;;

                        *)
                            echo false
                        ;;
                    esac
                ;;
            esac
        ;;
    esac
}

## 是否为车机项目
function is_car_project()
{
    case `get_project_real_name` in

        reglink_k100_develop|reglink_k100_ykt-0bihu|reglink_k100_cq|reglink_k100_cqhm|reglink_k100_ui2|reglink_k100_cardui-azure|reglink_k100_cardui-blue) ## reglink k100
            echo true
            ;;

        reglink_k100_cardui-xy|reglink_k100_cardui|reglink_k100_cpy|reglink_k100_cardui-colours|reglink_k100_cardui-black|reglink_k100_vst-a100|reglink_k100_cardui-mb|reglink_k100_k88c-cpy)
            echo true
            ;;

        reglink_k100_vst-a100s|reglink_k100_portrait-ui)
            echo true
            ;;

        reglink_k101_portrait-ui|reglink_k101_mb-pui)
            echo true
            ;;

        reglink_k104_ykt-0bihu) ## reglink k04
            echo true
            ;;

        droidcar_k100_test) ## droidcar k100
            echo true
            ;;

        along_k101_develop|along_k101_ui2|along_k101_cardui-cq|along_k101_mb|along_k101_cardui-ama30|along_k101_vst-a100|along_k101_ui-gs|along_k101_qc-t1|along_k101_ui-gs2) ## along k101
            echo true
            ;;

        along_k101_lyd-1|along_k101_cpy|along_k101_vst-a100s|along_k101_mb-x)
            echo true
            ;;

        along_k101_vst-d900) ## along k101 威仕特客户
            echo true
            ;;

        along_k106_ui2|along_k106_mb|along_k106_yunui|along_k106_yunui-mb|along_k106_vst|along_k106_vst-s102|along_k106_vst-m102|along_k106_qc-t1|along_k106_cpy|along_k106_cardui-fxft)
            echo true
            ;;

        along_k106_xlt|along_k106_jimi|along_k106_unicom|along_k106_by-a1|along_k106_ecar|k106_along_develop|along_k106_jimi-z|along_k106_ym|along_k106_fxft-q106|along_k106_mb-dz01)
            echo true
            ;;

        along_k106_lyra-zx)
            echo true
            ;;

        along_k108_ui2|along_k108_mb)
            echo true
            ;;

        k101_yunovo_bsp_only) ## k101 android7.0
            echo true
            ;;

        cm01_yunovo_navi|cm01_mb_a7g|cm01_mb_y9g|cm01_vst_a08|cm01_tl_zx|cm01_ll_zx|cm01_vst_a09|cm01_vst_a10|cm01_vst_b09|cm01_vst_b10) ## CM01 项目
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

## 中国移动招4g项目,mt6753兼容mt6735
function is_4g_project()
{
    case `get_project_real_name` in

        k88d_bdxl_zx5|k88d_bdxl_zx7|k88d_bdxl_zx8|k88d_baseline|k88d_hs_c1|k88d_bt_bt189|k88d_dhxl_ct001e|k88d_bdxl_zx7demo)
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

## 是否为mt6735t项目
function is_mt6735t_project()
{
    case `get_project_real_name` in

        k85_yunovo_develop)
            echo true
            ;;
        *)
            echo false
            ;;
    esac
}

## 是否为mt6737t项目
function is_mt6737t_project()
{
    case `get_project_real_name` in

        k68c_hs_c3-cta|k68c_cz_at1202-cta)
            echo true
            ;;

        k85_master|k86s-mx17_master|k68c_master|k897_master|k88c7_baseline|k86s-mx17_bsp4ali|k68c_hs_c1|k68c_cta|k68c_hs_c1debug|k68c_ctadebug|k68c_hs_c1demo|k68c_hs_c2|k68c_dhxl_cyt01-8t)
            echo true
            ;;

        k68c_fxft_dr088p|k68c_by_a2|k68c_dh_cyt01|k68c_by_a2-ahd|k68c_dh_cyt01debug)
            echo true
            ;;

        k68_master|k68_ldrh_ec|k68_baseline)
            echo true
            ;;

        k68c_bsp4ali)
            echo true
            ;;

        ## k60项目
        k60_master|k60_carrobot_develop|k60_carrobot_s1|k60_baseline|k60_carrobot_zx|k60_carrobot_fd)
            echo true
            ;;

        ## k61项目
        k61_master|k61_xy_c26|k61_zx_s988)
            echo true
            ;;

        ## 阿里项目
        mt6737t_master)
            echo true
            ;;

        k68d_master|k68d_dl_s7|k68d_etc_s4) ## k68d项目
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

## 是否为carrobot项目
function is_carrobot_project()
{
    case `get_project_real_name` in

        k60_carrobot_s1)
            echo true
            ;;
        *)
            echo false
            ;;
    esac
}

### 是否为云智易联项目
function is_yunovo_project
{
    case `get_project_real_name` in

        ## zen平台项目
        ${manifest_path})
            echo true
            ;;

        ## zen OTA
        mk26_nxos|mk26_stable|cm01_stable)
            echo true
            ;;

        ## 主分支
        k20_master|k21_master|k26_master|k26s_master|k27_master|k28s_master|mk01_master|mk21_master|mk26_master) ## 主分支MT6580
            echo true
            ;;

        k88c_master|k89_master|mx1_master|k88c_cta) ## 主分支MT6735
            echo true
            ;;

        cm01_master) ## 主分支 MT8321
            ;;

        k68c_master) ## 主分支 MT6737T
            echo true
            ;;

        tg88_master|ms16_master|cs01_master) ## 主分支 SC9832
            echo true
            ;;

        k26s1_zm01s)
            echo true
            ;;

        ##车机项目
        reglink_k100_develop|reglink_k100_ykt-0bihu|reglink_k100_cq|reglink_k100_cqhm|reglink_k100_ui2|reglink_k100_cardui|reglink_k100_cardui-azure) ## reglink k100
            echo true
            ;;

        reglink_k100_cpy|reglink_k100_cardui-blue|reglink_k100_cardui-colours|reglink_k100_cardui-black|reglink_k100_vst-a100|reglink_k100_cardui-mb|reglink_k100_k88c-cpy)
            echo true
            ;;

        reglink_k101_portrait-ui|reglink_k101_mb-pui)
            echo true
            ;;

        reglink_k100_cardui-xy|reglink_k100_vst-a100s|reglink_k100_portrait-ui)
            echo true
            ;;

        along_k101_develop|along_k101_ui2|along_k101_cardui-cq|along_k101_mb|along_k101_cardui-ama30|along_k101_vst-a100|along_k101_ui-gs|along_k101_qc-t1|along_k101_ui-gs2) ## along k101
            echo true
            ;;

        along_k101_lyd-1|along_k101_cpy|along_k101_vst-a100s|along_k101_mb-x)
            echo true
            ;;

        along_k101_vst-d900) ## along k101 威仕特客户
            echo true
            ;;

        along_k106_ui2|along_k106_mb|along_k106_yunui|along_k106_yunui-mb|along_k106_vst|along_k106_vst-s102|along_k106_vst-m102|along_k106_qc-t1|along_k106_cpy|along_k106_cardui-fxft)
            echo true
            ;;

        along_k106_lyra-zx|along_k106_xlt|along_k106_jimi|along_k106_unicom|along_k106_by-a1|along_k106_ecar|k106_along_develop|along_k106_jimi-z|along_k106_ym|along_k106_fxft-q106|along_k106_mb-dz01)
            echo true
            ;;

        along_k108_ui2|along_k108_mb)
            echo true
            ;;

        reglink_k104_ykt-0bihu) ## reglink k104
            echo true
            ;;

        droidcar_k100_test) ## droidcar k100
            echo true
            ;;

        k101_yunovo_bsp_only) ## k101 android7.0
            echo true
            ;;
        cm01_yunovo_navi|cm01_mb_a7g|cm01_mb_y9g|cm01_vst_a08|cm01_tl_zx|cm01_ll_zx|cm01_vst_a09|cm01_vst_a10|cm01_vst_b09|cm01_vst_b10) ## CM01 项目
            echo true
            ;;

        ## 车镜单独分支
        mx1_teyes_t7|mx1_teyes_t72|mx1_yunovo_zx|mtk6735_gps_master) ## 分支项目
            echo true
            ;;

        k26b_vst_s2|k26b_fxft_h480|k26s_vst_s1|k26s_vst_s2|k26s_newsmy_d900|k26s_vst_k3|k26s_vst_dh630|k26s_vst_i9|k26s_vst_h8|k26s_vst_f8) ## vst k26e版型
            echo true
            ;;

        k26e_hp_m1|k26e_dwt_t02|k26e_jd_t2)
            echo true
            ;;

        k26s1_vst_i8|k26s1_vst_h8|k26s1_vst_k7|k26s1_vst_k7s|k26s1_vst_f8|k26s1_vst_i8s|k26s1_vst_k3|k26s1_dwt_t02|k26s1_lejia_d800|k26s1_lejia_d880|k26s1_vst_dh630) ## vst k26s版型
            echo true
            ;;

        k26s1_dwt_u18|k26s1_bhz_x700a-wf|k26s1_kkxl_k8s|k26s1_jm_crf02|k26s1_vst_k8|k26s1_dwt_t028c|k26s1_lyd_b9|k26s1_vst_c8|k26s1_vst_h8s|k26s1_anytek_n100|k26s1_anytek_n6plus|k26s1_ld_hs830c)
            echo true
            ;;

        k26s1_fxft_dr066s|k26s1_vst_c5|k26s1_yt_p510|k26s1_yt_p510a|k26s1_yt_v610|k26s1_yt_v610a|k26s1_yt_v610-zx|k26s1_vst_k7m|k26s1_xinke_d620|k26s1_vst_c101|k26s1_vst_k3s|k26s1_vst_d609)
            echo true
            ;;

        k26s1_vst_h8m|k26s1_yz_zx|k26s1_vst_h8f|k26s1_vst_h8e|k26s1_vst_k7f|k26s1_vst_k7e|k26s1_vst_h8k|k26s1_vst_k3k)
            echo true
            ;;

        k26s_ld_a107c|k26s_vst_a1a|k26s_vst_a2a|k26s_fxft_h481|k26s_vst_a1|k26s_vst_a2|k26s_fxft_dr066|k26s_jm_crf02|k26s_xy_c18|k26s_zh_sg8007|k26s_zh_sg8008|k26s_anytek_q996plus)
            echo true
            ;;

        k26s_xianzhi_t99|k26_vst_s1|k26f_byos_s5|k26e_vst_k3|k26s_vst_k3mg|k26s_vst_k8|k26_vst_open|k26_vst_release|k26_vst_debug|k26_vst_i8|k26_vst_i8s|k26s_vst_k7|k26s_zx_t8s)
            echo true
            ;;

        k26s_teyes_a8r|k26s_zx_t6|k26s_anytek_a918|k26s_fxft_dr066s|k26s_zx_t8i)
            echo true
            ;;

        k26_vst_i8n)
            echo true
            ;;

        mk26_s9_zx)
            echo true
            ;;

        k27_hbs_t2|k27_xinke_ds50|k27_aj_ajs-1|k27_vst_d1|k27l_fxft_c66|k27_vst_k5|k27_vst_d800|k27_qc_r02|k27e_xinke_ds57|k27_lj_d680|k27_lyd_h12|k27_lj_d680v1|k27_qc_m6plus-d30) ## k27 版型
            echo true
            ;;

        k28s_ld_a107c|k28s_ld_hs995d|k28s_rwy_cs85|k28s_ld_a107cyz)
            echo true
            ;;

        ## k68 版型项目 电话机
        k68_ldrh_ec)
            echo true
            ;;

        ## k68c 版型项目
        k68c_hs_c1|k68c_hs_c1debug|k68c_hs_c1demo|k68c_hs_c2|k68c_dhxl_cyt01-8t|k68c_fxft_dr088p|k68c_by_a2|k68c_dh_cyt01|k68c_by_a2-ahd|k68c_dh_cyt01debug)
            echo true
            ;;

        ## k88c 版型项目
        k88c_jm_cm01|k88c_jm01_cm01|k88c_bt_bt188|k88c_noain_cr01|k88c_meiban_sq01|k88c_fxft_dr088|k88c_fxft_dr088s|k88c_jm_crf01|k88c_qc_jnx18|k88c_nh_x18|k88c_fxft_dr088p)
            echo true
            ;;

        k88c_bdxl_cyt01|k88c_bdxl_ct001|k88c_bdxl_ct006|k88c_hs_c1|k88c_qc_x2|k88c_bdxl_cyt01df|k88c_qc_x2c|k88c_qc_x2adv|k88c_bdxl_cm04|k88c_yls_tpl86s-c|k88c_yls_tpl86s-c-zx|k88c_bdxl_cm50)
            echo true
            ;;

        k88c_bdxl_ct002|k88c_bdxl_cyt02|k88c_jm_ym8a|k88c_jm_jy10|k88c_bdxl_cyt01m|k88c_s5_zx|k88c_lj_h5|k88c_dhxl_cyt01-5t|k88c_fxft_dr089p|k88c_dhxl_xl-d40)
            echo true
            ;;

        k88c_fxft_dr089x|k88c_cz_cyt01|k88c_fxft_dr089q|k88c_ll_zx|k88c_bdxl_cyt01-fg)
            echo true
            ;;

        ## k88c7 版型项目
        k88c7_baseline)
            echo true
            ;;

        k68c_cta|k68c_ctadebug|k68c_bsp4ali|k68c_hs_c3-cta|k68c_cz_at1202-cta)
            echo true
            ;;

        k26_vst_cta)
            echo true
            ;;

        k68d_master|k68d_dl_s7|k68d_etc_s4) ## k68d 版型项目
            echo true
            ;;

        ## k60 版型项目
        k60_master|k60_carrobot_develop|k60_carrobot_s1|k60_baseline|k60_carrobot_zx|k60_carrobot_fd)
            echo true
            ;;

        k61_master|k61_xy_c26|k61_zx_s988) ## k61版型项目
            echo true
            ;;

        k86_master)
            echo true
            ;;

        k86s-mx17_bsp4ali)
            echo true
            ;;

        k89_ld_hs720a|k89_zc_develop|k89_vst_i8m|k89_jd_d_cucc4g|k89_yxf7_kd001|k89_yxf5_kd001|k89_gm_t99|k89_xianzhi_t99|k89_s6_zx)
            echo true
            ;;

        mx1_xianzhi_t80c|mx1_xianzhi_t80|mx1_anytek_ty990)
            echo true
            ;;

        k86mx1_jh_s04a|k86mx1_rwy_dz80|k86mx1_byos_s8|k86mx1_meiban_m8a|k86mx1_meiban_m8s|k86mx1_kkxl_c9|k86mx1_kkxl_c9x|k86mx1_jlrx_m3|k86mx1_jlrx_h3|k86mx1_qc_m78)
            echo true
            ;;

        k86mx1_zxos_s8|k86mx1_jlrx_zx|k86mx1_nzjos_s8)
            echo true
            ;;

        k86sa1_tpl_tpl86s-hd|k86sa1_tpl_tpl86s-qhd|k86sa1_mazda_master|k86sa1_meiban_m4z)
            echo true
            ;;

        k88c_6735_VoLTE_develop|mtk6753_volte_develop|mtk6735_gps_develop)
            echo true
            ;;

        k86s7_wc_vs188|k86s7_yls_s7|k86s7_qc_m78|k86s7_qc_m78mzd|k86s7_qc_m78zx)
            echo true
            ;;

        k86l_linghz_q18)
            echo true
            ;;

        k85_yunovo_develop) ## k85版型
            echo true
            ;;

        k86s_netop_develop) ## 晋阳客户
            echo true
            ;;

        k86mx1_meiban_m8stest|k86mx1_meiban_m8atest|k86sa1_tpl_tpl86s_hdtest|k26e_bhz_x700test|k26e_qc_x18test|k88c_bt_bt188test|k86sa1_mazda_mastertest0|k86sa1_mazda_mastertest1) ## 还原基准包
            echo true
            ;;

        k27_kkxl_s6test|mx1_xianzhi_t80ctest|k68c_ctadebug)
            echo true
            ;;

        k26e_sogou_zx|mx1_xianzhi_k80d|k86mx1_tpl_tpl86s-hd|k26s_lejia_d880|k26s_lejia_d800|k88c_qc_x2a) ## 分支项目
            echo true
            ;;

        k88d_bdxl_zx5|k88d_bdxl_zx7|k88d_bdxl_zx8|k88d_baseline|k88d_hs_c1|k88d_bt_bt189|k88d_dhxl_ct001e|k88d_bdxl_zx7demo) ## k88d版型分支
            echo true
            ;;

        k26s_kkxl_k8|k26s_dwt_t02) ##封板软件
            echo true
            ;;

        k26s_meiban_m30|k26s_meiban_m50|k26s_meiban_m60|k26s_qc_yx88|k26a_yls_a5|mx1_xianzhi_k80|mx1_xianzhi_k80e|k26e_qc_x18|k26e_bhz_x700|k26e_bhz_x700a|k26e_bhz_bh981|k26e_newsmy_d910)
            echo true
            ;;

        k26s_lejia_d800r|k26e_hp_s750b|k26e_kkxl_k8s|k26e_bhz_bh970|k26e_bhz_bh976|k26e_bhz_x700a-wf|k26e_bhz_bh970-wf|k26e_bhz_bh976-wf|k26e_bhz_x700m)
            echo true
            ;;

        k26e_hp_s750m|k26e_zx_t8s)
            echo true
            ;;

        k27_kkxl_s6|k27_byos_k5)
            echo true
            ;;

        k21_s7_zx|k21_s9_zxlmt|k21_vst_s6|k21_mb_m70|k21_lhz_t9s) ## k21版型分支
            echo true
            ;;

        c2m_master)
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

### 是否为阿里的项目
function is_yunos_project
{
    case `get_project_real_name` in

        mk26_jd_zx)
            echo true
            ;;

        mx1_kkxl_v9|mx1_kkxl_v9_ts|mx1_teyes_t8|mx1_teyes_t8s|mx1_teyes_t8_new|mx1_anytek_m960|mx1_teyes_t7|mx1_renwoyou_dz86|mx1_teyes_t8sRu)
            echo true
            ;;

        mx1_teyes_t8s2.0|mx1_ln_s3)
            echo true
            ;;

        mx2_teyes_t8|mx2_teys_t8_new)
            echo true
            ;;

        k88c_lufeng_f100|k88c_cocolife_v6-k|k88c_cocolife_v6-p)
            echo true
            ;;

        k26s_vst_i7|k26s_vst_i7s|k26s_renwoyou_cs86|k26s_qch_x88|k26s_hp_s760|k26s_xy_c18|k26s_xy_c18s|k26s_teyes_a8|k26s_vst_gps|k26s_rwy_cs60)
            echo true
            ;;

        k26e_hp_s730|k26e_hp_s750|k26s_xy_c18m|k26e_jd_d210_plus|k26s_th_c18m|k26s_qch_x18)
            echo true
            ;;

        k89_hp_s760d|k89_xy_c30)
            echo true
            ;;

        mt6737t_master)
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

## 获取项目真实名称
function get_project_real_name()
{
    local thisP=`pwd | awk -F/ '{print $(NF-1)}'`

    if [[ -n "${thisP}" ]];then
        echo "${thisP}"
    else
        log error "Get project name is null ..."
    fi
}

##　是否为root项目
function is_root_project()
{
    case ${build_type} in

        userdebug|eng)
            echo true
            ;;

        user)
            echo false
            ;;

        *)
            echo false
            ;;
    esac
}

### 是否为编译服务器
function is_yunovo_server()
{
    case `hostname` in

        s1|s2|s4|s5|s6|s7|f1|c1|c2|d1|d4|happysongs|hhz|mcjerdy|system)
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

### 是否为master test develop分支
function is_yunovo_branch()
{
    local branchN=$1

    case ${branchN} in

        master|develop|test)
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

### 是否为使用的芯片类型
function is_build_device()
{
    case ${build_device} in

        magc6580_we_l)
            echo true
            ;;

        aeon6735_65c_s_l1|aeon6735m_65c_s_l1|aeon6735_66c_m0|aeon6737t_66_m0|aeon6737m_65_m0)
            echo true
            ;;

        along8321_emmc_706m)
            echo true
            ;;

        neostra8321_3g)
            echo true
            ;;

        tg88_demo|yunovo)
           echo true
           ;;

        k80_bsp|k62v1_64_bsp|k37mv1_64_bsp)
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

### 是否为正确的编译类型
function is_build_type()
{
    case ${build_type} in

        user|userdebug|eng)
            echo true
            ;;
        *)
            echo false
            ;;
    esac
}

# 支持构建假包
function is_support_fake() {

    case ${yunovo_board} in

        cm01|cm02)
            echo true
            ;;

        ck02)
            echo true
            ;;

        ck05)
            echo true
            ;;

        ms16|ms18)
            echo true
            ;;

        *)
            echo false
        ;;
    esac
}

# 是否为android5.1版本
function is_51_android() {

    case `get_project_name` in

        *)
            case `get_manifest_branch` in

                ck02/master)
                    echo true
                    ;;
                *)
                    case ${yunovo_board} in
                        k21|mk21|mk26|mk01|mk28)
                            echo true
                            ;;

                        cm01|cm02)
                            echo true
                            ;;

                        *)
                            if [[ `get_platform_version_form_mk` =~ 5.1 ]]; then
                                echo true
                            elif [[ `get_platform_version` =~ 5.1 ]]; then
                                echo true
                            else
                                echo false
                            fi
                            ;;
                    esac
                    ;;
            esac
            ;;
    esac
}

# 是否为android6.0版本
function is_60_android() {

    case `get_project_name` in

        *)
            case ${yunovo_board} in

                cs01|ms16|ms18)
                    echo true
                    ;;

                k68c)
                    echo true
                    ;;

                *)
                    if [[ `get_platform_version_form_mk` =~ 6.0 ]]; then
                        echo true
                    elif [[ `get_platform_version` =~ 6.0 ]];then
                        echo true
                    else
                        echo false
                    fi
                    ;;
            esac
            ;;
    esac
}

# 是否为android8.1版本
function is_81_android() {

    case `get_project_name` in

        *)
            case `get_manifest_branch` in

                ck02/oreo/master)
                    echo true
                    ;;

                *)
                    case ${yunovo_board} in

                        ck05|ck06)
                            echo true
                            ;;

                        *)
                            if [[ `get_platform_version_form_mk` =~ 8.1 ]]; then
                                echo true
                            elif [[ `get_platform_version` =~ 8.1 ]];then
                                echo true
                            else
                                echo false
                            fi
                            ;;
                    esac
                    ;;
            esac
            ;;
    esac
}

# 是否为android9.0.0版本
function is_90_android() {

    case `get_project_name` in

        *)
            case ${yunovo_board} in

                *)
                    if [[ `get_platform_version_form_mk` =~ 9 ]]; then
                        echo true
                    elif [[ `get_platform_version` =~ 9 ]];then
                        echo true
                    else
                        echo false
                    fi
                    ;;
            esac
            ;;
    esac
}

## 拿到具体的版型
function get_board_type() {

    if [[ -n "${yunovo_board}" ]]; then
        echo "${yunovo_board}"
    else
        echo null
    fi
}

## android系统版本
function get_android_version()
{
    case ${build_device} in

        aeon6735_65c_s_l1|aeon6735m_65c_s_l1|magc6580_we_l|along8321_emmc_706m)
            echo "5.1"
            ;;

        aeon6735_66c_m0|aeon6737t_66_m0|aeon6737m_65_m0|yunovo)
            echo "6.0"
            ;;

        neostra8321_3g)
            echo "7.0"
            ;;

        k80_bsp|k37mv1_64_bsp|k62v1_64_bsp)
            echo "8.1"
            ;;

        *)
            if [[ "`is_51_android`" == "true" ]]; then
                echo "5.1"
            elif [[ "`is_60_android`" == "true" ]];then
                echo "6.0"
            elif [[ "`is_81_android`" == "true" ]];then
                echo "8.1"
            elif [[ "`is_90_android`" == "true" ]];then
                echo "9.0"
            else
                echo "null"
            fi
            ;;
    esac
}

## 获取Android平台版本，最精准但效率会低些，相对get_platform_version_form_mk
function get_platform_version() {

    if [[ ${SOURCE_ANDROID} == "true" ]]; then
        get_build_var PLATFORM_VERSION
    fi
}

## 获取Android平台版本, 最精准且效率高，故先执行
function get_platform_version_form_mk() {

    if [[ -f build/core/version_defaults.mk ]]; then
        cat build/core/version_defaults.mk | egrep -w "^PLATFORM_VERSION.OPM1 :=|PLATFORM_VERSION :=|PLATFORM_VERSION.PPR1" | head -1 | awk '{print $NF}'
    fi
}

## 获取项目版本号
function get_project_name() {

    if [[ -n ${yunovo_board} && -n ${yunovo_custom} && -n ${yunovo_project} ]]; then
        echo "${yunovo_board}/${yunovo_custom}/${yunovo_project}" | tr '[:upper:]' '[:lower:]'
    fi
}

## 获取项目manifest分支名
function get_manifest_branch() {

    if [[ -n ${manifest_branchN} ]]; then
        echo ${manifest_branchN}
    fi
}

## 获取芯片类型
function get_cpu_type()
{
    case ${build_device} in

        magc6580_we_l)
            echo "mt6580"
            ;;

        aeon6735_65c_s_l1|aeon6735m_65c_s_l1|aeon6735_66c_m0)
            echo "mt6735"
            ;;

        aeon6737t_66_m0|aeon6737m_65_m0)
            echo "mt6737t"
            ;;

        along8321_emmc_706m)
            echo "mt8321"
            ;;

        tg88_demo)
            echo "sc9832a"
            ;;

        k80_bsp)
            echo "mt6580-oreo"
            ;;

        k62v1_64_bsp)
            echo "mt6762"
            ;;

        k37mv1_64_bsp)
            echo "mt6737m"
            ;;

        *)
            case ${yunovo_board} in
                k21|mk21|mk26|mk01|mk28)
                    echo "mt6580"
                    ;;

                cm01|cm02)
                    echo "mt8321"
                    ;;

                cs01|ms16|ms18)
                    echo "sc9832a"
                    ;;

                k68c)
                    echo "mt6737t"
                    ;;

                ck02|ck03)
                    if [[ "`is_51_android`" == "true" ]]; then
                        echo "mt8321"
                    else
                        echo "mt6580-oreo"
                    fi
                    ;;

                ck05)
                    echo "mt6737m"
                    ;;

                ck06)
                    echo "mt6762"
                    ;;
                *)
                    :
                    ;;
            esac
            ;;
    esac
}

# 获取设备类型
function get_device_type() {

    case ${yunovo_board} in

        k21|mk21|mk26|mk01|mk28)
            echo magc6580_we_l
            ;;

        cm01|cm02)
            echo along8321_emmc_706m
            ;;

        cs01|ms16|ms18)
            echo yunovo
            ;;

        k68c)
            echo aeon6737t_66_m0
            ;;

        ck02|ck03)
            if [[ "`is_51_android`" == "true" ]]; then
                echo along8321_emmc_706m
            else
                echo k80_bsp
            fi
            ;;

        ck05)
            echo k37mv1_64_bsp
            ;;

        ck06)
            echo k62v1_64_bsp
            ;;

        *)
            :
            ;;
    esac
}

## 是否编译公版软件
function is_public_project()
{
    shellfs=${shellfs##*/}

    case ${shellfs} in
        makefs.sh)
            echo true
            ;;
        *)
            case `get_project_real_name` in
                k68c_cz_at1202-cta|k26_vst_cta)
                    echo true
                    ;;
                *)
                    echo false
                ;;
            esac
            ;;
    esac
}

## 是否编译android系统脚本
function is_android_project()
{
    shellfs=${shellfs##*/}

    case ${shellfs} in

        makefs.sh|make_android.sh|repo_diffmanifests.sh)
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

## 是否构建OTA差分包项目
function is_inc_project() {

    shellfs=${shellfs##*/}

    case ${shellfs} in

        build_ota.sh)
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

## 是否执行发布版本
function is_rom_release() {

    shellfs=${shellfs##*/}

    case ${shellfs} in

        rom_release.sh)
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

## 返回4的错误的log的脚本
function is_4_return() {

    shellfs=${shellfs##*/}

    case ${shellfs} in
        repo_diffmanifests.sh)
            echo true
            ;;
        *)
            echo false
            ;;
    esac
}

## 返回5的错误的log的脚本
function is_5_return() {

    shellfs=${shellfs##*/}

    case ${shellfs} in
        build_ota.sh)
            echo true
            ;;
        *)
            echo false
            ;;
    esac
}

## 是否为32位库文件
function is_lib32_platfrom() {

    case ${yunovo_board} in

        k21|mk21|mk26|mk01|mk28)
            echo true
            ;;

        cs01|ms16|ms18)
            echo true
            ;;

        cm01|cm02)
            echo true
            ;;

        *)
            case `get_cpu_type` in

                mt8321|sc9832a)
                    echo true
                    ;;

                *)
                    if [[ "`get-target-arch`" == "arm" ]]; then
                        echo true
                    else
                        echo false
                    fi
                    ;;
             esac
        ;;
    esac
}

## 是否为64库文件
function is_lib64_platfrom() {

    case ${yunovo_board} in

        k68c)
            echo true
            ;;

        ck05)
            echo true
            ;;

        *)
            case `get_cpu_type` in

                mt6737t|mt6737m)
                    echo true
                    ;;

                *)
                    if [[ "`get-target-arch`" == "arm64" ]]; then
                        echo true
                    else
                        echo false
                    fi
                    ;;
            esac
    esac
}

## 是否编译应用项目
function is_app_project()
{
    shellfs=${shellfs##*/}

    case ${shellfs} in
        make_nxos.sh)
            echo true
            ;;
        *)
            echo false
            ;;
    esac
}


## 是否为ODM分区项目
function is_odm_partition() {

    case ${yunovo_board} in

        ck02)
            if [[ "`is_81_android`" == "true" ]]; then
                echo true
            else
                echo false
            fi
            ;;

        ck05|ck06)
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

## 是否为OEM分区项目
function is_oem_partition() {

    case ${yunovo_board} in

        ms16)
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

## 是否升级preloader和lk
function is_ota_preloader() {

    case `get_project_real_name` in

        cm01_stable|ck02_master)
            echo true
            ;;
        *)
            echo false
            ;;
    esac
}

## 是否需要override
function is_override_module() {

    case ${build_release_app} in

        nxSystemUI)
            build_override_module=SystemUI
            echo true
        ;;

        nxLauncher)
            build_override_module=Launcher3
            echo true
        ;;

        *)
            echo false
        ;;
    esac
}
