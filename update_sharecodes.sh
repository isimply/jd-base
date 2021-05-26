#!/usr/bin/env bash

## 路径、环境判断
ShellDir=${JD_DIR:-$(
  cd "$(dirname "$0")" || exit
  pwd
)}
LogDir=${ShellDir}/log
ConfigDir=${ShellDir}/config
FileConf=${ConfigDir}/config.sh
[[ ${ANDROID_RUNTIME_ROOT}${ANDROID_ROOT} ]] && Opt="P" || Opt="E"
Tips="从日志中未找到任何互助码..."
UserSum=0
HelpType=

## 所有有互助码的活动，只需要把脚本名称去掉前缀 jd_ 后列在 Name1 中，将其中文名称列在 Name2 中，对应 config.sh 中互助码后缀列在 Name3 中即可。
## Name1、Name2 和 Name3 中的三个名称必须一一对应。
Name1=(fruit pet plantBean dreamFactory jdfactory crazy_joy jdzz jxnc bookshop city sgmh cfd health carnivalcity)
Name2=(东东农场 东东萌宠 京东种豆得豆 京喜工厂 东东工厂 crazyJoy任务 京东赚赚 京喜农场 口袋书店 城城领现金 闪购盲盒 京喜财富岛 东东健康社区 京东手机狂欢城)
Name3=(Fruit Pet Bean DreamFactory JdFactory Joy Jdzz Jxnc BookShop City Sgmh Jdcfd Health Carni)

## 导入 config.sh
function Import_Conf {
  if [ -f "${FileConf}" ]; then
    if [[ $(grep -c "^Cookie\([0-9]\{1,3\}\)=\"pt_key" "${FileConf}") -lt 1 ]]; then
      echo -e "请先在Cookie管理中添加一条Cookie...\n"
      exit 1
    fi
  else
    echo -e "配置文件 ${FileConf} 不存在，请先按教程配置好该文件...\n"
    exit 1
  fi
}

## 用户数量 UserSum
function Count_UserSum {
  UserSum=$(grep -c "^Cookie\([0-9]\{1,3\}\)=\"pt_key" "${FileConf}")
}

## 导出互助码的通用程序
function Cat_Scodes {
  if [ -d "${LogDir}"/jd_"$1" ] && [[ $(ls "${LogDir}"/jd_"$1") != "" ]]; then
    cd "${LogDir}"/jd_"$1" || exit

    local codes
    ## 导出助力码变量（My）
    for log in $(ls -r); do
      case $# in
      2)
        codes=$(grep -${Opt} "开始【京东账号|您的(好友)?助力码为" "${log}" | uniq | perl -0777 -pe "{s|\*||g; s|开始||g; s|\n您的(好友)?助力码为(：)?:?|：|g; s|，.+||g}" | sed -r "s/【京东账号/My$2/;s/】.*?：/='/;s/】.*?/='/;s/$/'/;s/\(每次运行都变化,不影响\)//")
        ;;
      3)
        codes=$(grep -${Opt} "$3" "${log}" | uniq | sed -r "s/【京东账号/My$2/;s/（.*?】/='/;s/$/'/")
        ;;
      esac
      if [[ ${codes} ]]; then
        ## 添加判断，若未找到该用户互助码，则设置为空值
        for user_num in $(seq 1 "${UserSum}"); do
          echo -e "${codes}" | grep -${Opt}q "My$2${user_num}="
          if [ $? -eq 1 ]; then
            if [ "$user_num" == 1 ]; then
              codes=$(echo "${codes}" | sed -r "1i My${2}1=''")
            else
              codes=$(echo "${codes}" | sed -r "/My$2$((user_num - 1))=/a\My$2${user_num}=''")
            fi
          fi
        done
        break
      fi
    done

    ## 导出为他人助力变量（ForOther）
    if [[ ${codes} ]]; then
      local left_str
      local right_str
      local mark
      local help_code
      local for_other_codes
      local new_code
      help_code=""
      for user_num in $(seq 1 "${UserSum}"); do
        echo -e "${codes}" | grep -${Opt}q "My$2${user_num}=''"
        if [ $? -eq 1 ]; then
          help_code=${help_code}"\${My"$2${user_num}"}@"
        fi
      done
      ## 生成互助规则模板
      for_other_codes=""
      case $HelpType in
      0) ### 统一优先级助力模板
        new_code="${help_code//@$//}"
        for user_num in $(seq 1 "${UserSum}"); do
          if [ "$user_num" == 1 ]; then
            for_other_codes=${for_other_codes}"ForOther"$2${user_num}"=\"${new_code}\"\n"
          else
            for_other_codes=${for_other_codes}"ForOther"$2${user_num}"=\"\${ForOther"${2}1"}\"\n"
          fi
        done
        ;;
      1) ### 均匀助力模板
        for user_num in $(seq 1 "${UserSum}"); do
          if ! grep <"${help_code}" "\${My""$2""${user_num}""}@" >/dev/null; then
            left_str=$(echo "${help_code}" | sed "s/${mark}/ /g" | awk '{print $1}')${mark}
            right_str=$(echo "${help_code}" | sed "s/${mark}/ /g" | awk '{print $2}')
          else
            left_str=$(echo "${help_code}" | sed "s/\${My$2${user_num}}@/ /g" | awk '{print $1}')
            right_str=$(echo "${help_code}" | sed "s/\${My$2${user_num}}@/ /g" | awk '{print $2}')
            mark="\${My$2${user_num}}@"
          fi
          new_code=$(echo "${right_str}""${left_str}" | sed "s/@$//")
          for_other_codes=${for_other_codes}"ForOther"$2${user_num}"=\"${new_code}\"\n"
        done
        ;;
      *) ### 普通优先级助力模板
        for user_num in $(seq 1 "${UserSum}"); do
          new_code=$(echo "${help_code}" | sed "s/\${My""$2""${user_num}""}@//;s/@$//")
          for_other_codes=${for_other_codes}"ForOther"$2${user_num}"=\"${new_code}\"\n"
        done
        ;;
      esac
      echo -e "${codes}\n\n${for_other_codes}" | sed s/[[:space:]]//g
    else
      echo ${Tips}
    fi
  else
    echo "未运行过 jd_$1 脚本，未产生日志"
  fi
}

## 汇总
function Cat_All {
  local Temp_Cat_Scodes
  for ((i = 0; i < ${#Name1[*]}; i++)); do
    echo -e "\n${Name2[i]}："
    Temp_Cat_Scodes=$(Cat_Scodes "${Name1[i]}" "${Name3[i]}" "的${Name2[i]}好友互助码")
    if [[ "${Temp_Cat_Scodes}" == "${Tips}" ]]; then
      if [[ "${Name3[i]}" == "Cash" ]]; then
        Cat_Scodes "${Name1[i]}" "${Name3[i]}" "${Name2[i]}"
      else
        Cat_Scodes "${Name1[i]}" "${Name3[i]}"
      fi
    else
      echo -e "${Temp_Cat_Scodes}"
    fi
  done
}

## 更新配置文件里互助码跟互助方式
function Update_Help_Codes {
  Count_UserSum
  local TmpRes
  local TmpVar
  if [[ ${UserSum} -ge 1 ]]; then
    for ((i = 0; i < ${#Name1[*]}; i++)); do
      if [[ ${Export_Scodes} =~ "My"${Name3[i]} ]] && [[ $(grep -c "^My""${Name3[i]}""1" "${FileConf}") -ge 1 ]]; then
        ## 转换为可以替换的字符串
        TmpRes=""
        for j in $(seq 1 "${UserSum}"); do
          TmpVar=$(echo "${Export_Scodes}" | sed -n "s/^My${Name3[i]}${j}=\(.*\)$/\1/p")
          [ -n "${TmpVar}" ] && TmpRes="${TmpRes}My${Name3[i]}${j}=${TmpVar}\n" || TmpRes="${TmpRes}My${Name3[i]}${j}=\'\'\n"
        done
        #TmpRes=$(echo -e "${Export_Scodes}" | sed -n "/^My${Name3[i]}1=/,/^$/p")
        ## 更新配置文件互助码变量
        sed -i "/^My${Name3[i]}1=/,/^$/c ${TmpRes}" "${FileConf}"
      fi
      if [[ ${Export_Scodes} =~ "ForOther"${Name3[i]} ]] && [[ $(grep -c "^ForOther""${Name3[i]}""1" "${FileConf}") -ge 1 ]]; then
        ## 转换为可以替换的字符串
        TmpRes=""
        for j in $(seq 1 "${UserSum}"); do
          TmpVar=$(echo "${Export_Scodes}" | sed -n "s/^ForOther${Name3[i]}${j}=\(.*\)$/\1/p")
          [ -n "${TmpVar}" ] && TmpRes="${TmpRes}ForOther${Name3[i]}${j}=${TmpVar}\n" || TmpRes="${TmpRes}ForOther${Name3[i]}${j}=\"\"\n"
        done
        #TmpRes=$(echo -e "${Export_Scodes}" | sed -n "/^ForOther${Name3[i]}1=/,/^$/p")
        ## 更新配置文件互助方式变量
        sed -i "/^ForOther${Name3[i]}1=/,/^$/c ${TmpRes}" "${FileConf}"
      fi
    done
  fi
}

## 执行并写入配置文件
Export_Scodes=$(Import_Conf && Count_UserSum && Cat_All | perl -pe "{s|京东种豆|种豆|; s|crazyJoy任务|疯狂的JOY|}")
Update_Help_Codes
