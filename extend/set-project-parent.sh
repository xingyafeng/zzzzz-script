#!/usr/bin/env bash

function main() {

    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/CarAudioManager       --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/CarBTKey              --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/CarBack               --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/CarBandMode           --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/CarDog                --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/CarLogTools           --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/CarTools              --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/CmytUpdate            --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/CoDriver              --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/Dina_BLE_X            --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/Dina_vin              --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/DriverMonitor         --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/GocSdk                --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/HBS_AOTA              --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/HumanService          --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/IqiyiHD               --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/KuaiXiuKuaiBao        --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/MapgooApp             --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/MazdaYujia            --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/NewsmyNewyan          --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/NewsmyRecorder        --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/NewsmySPTAdapter      --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/OpenCVManager         --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/OrangeFolder          --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/OrangeLogin           --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/OrangeNavi            --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/OrangeNetService      --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/OrangeVoice           --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/ShizhuanVideo         --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/SohuVideo             --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/SouInputMethod        --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/StormVideo            --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/TeJiaMall             --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/Test                  --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/WeiZhangSearch        --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/XiaowoDF              --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/XiaowoDF2             --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/YOcTfChecked          --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/YidaoCar              --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/YiqiRelease           --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/iFlyIME               --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/icfw                  --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/k86a_script           --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/k86s_script           --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/mapgoo                --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/ssh_script            --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/yiqidaohang           --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/yiqidrivinganalysis   --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/yiqipeihuo            --parent yunovo_packages/CarEngine
    ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent yunovo_packages/yiqiyuyue             --parent yunovo_packages/CarEngine

}

main $@
