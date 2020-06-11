#!/usr/bin/sh
# 如果不管分支名直接注释即可
#branch="yunos/k26s/vst/i7s"
# 如果不管作者，注释即可
owner="柏伟 <baiw@yunovo.cn>"
# gerp 过滤掉不审核的仓库 ，自己调好，注意语法， -v是不匹配
grep_filter_proj=" -v -e yunovo/packages/apks/YOcSystemSetting -e yunovo/system/yovd -e yunovo/device "
# 不重要，会自行遍历出来
project="a"
user=xiongkaihao
hosts=gerrit-in.yunovo.cn
port=29419
# 必须有参数，不然会把所有人都审核了，太危险
[ -z "$owner" ] && [ -z "$branch" ] && exit ; 
#填充默认所需的参数
owner=${owner:+owner:\"$owner\"}
branch=${branch:+branch:\"$branch\"}
grep_filter_proj=${grep_filter_proj:- -v \"\\0\"}
# 指定分支名 ，指定作者 ， 找project list排重 ， 并去掉 project: , 如果没有仓库名过滤条件就显示所有,否则以指定条件过滤
run_shell="ssh -p $port ${user}@${hosts} gerrit query status:open ${owner} ${branch} | grep --color=never "project:" | sort | uniq | cut -d : -f 2 | grep --color=never ${grep_filter_proj}"
echo " $run_shell"
PJS=$(ssh -p $port ${user}@${hosts} gerrit query status:open ${owner} ${branch} | grep --color=never "project:" | sort | uniq | cut -d : -f 2 | grep --color=never ${grep_filter_proj} )
echo "-- $PJS -- were review $branch , enter key continue -- "
read
# 找指定project , 如果不去掉空格会导致遍历时分隔符号辨认失败
for project in $PJS ; do
 echo " *********** ${project} ************ "
 echo 
 #已经排好序的为正序，需要倒序审核  --patch-sets 目前和 --current-patch-set 一样，暂时没发现区别，如果有amend提交可能会有区别
 IDS=$(ssh -p $port ${user}@${hosts} gerrit query --current-patch-set status:open ${owner} ${branch} ${project:+project:\"$project\"} | grep "revision:" | nl | sort -nr | cut -d : -f 2 |tr "\n" " " )
 echo " review $project $IDS "
 #ssh -p $port ${user}@${hosts} gerrit review --code-review +2 -submit --project $project $IDS
# ssh -p $port ${user}@$hosts gerrit review --submit --project $project $IDS
 #break
done

exit
#ssh -p $port ${user}@$hosts gerrit review --code-review +2 --submit --project code/platform/external/aac change Ied8f3e6484f633be79d4b8680f31be224211cdf5
