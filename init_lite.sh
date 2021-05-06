#!/usr/bin/env bash
: '
@File   : init.sh
@Author : yangtonggang
@Date   : 2020-03-31
@Desc   : 增量更新，只更新证书和cts工具
'
CURRENT_PATH=$(cd "$(dirname "$0")" && pwd)
RESOURCE="$CURRENT_PATH"/../Resource/
echo "$RESOURCE"
start(){
  echo "安装证书"
  sh "$RESOURCE"/Certificates/install_prov_p12.sh
  echo "证书安装"

  echo "安装命令行"
  cd "/usr/local/bin" || exit
  rm -rf cts
  # ln -s "$RESOURCE"/cts cts
  cp "$RESOURCE"/cts cts
  echo "命令行安装"
}

start
echo "初始化完成"
