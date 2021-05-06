#!/usr/bin/env bash
: '
@File   : init.sh
@Author : yangtonggang
@Date   : 2020-03-31
@Desc   : cts 仓库初始化工程（无需人工调用）
'
NAME=$1
ROOT_PATH=$2
GIT_CLONE="ssh://$NAME@icode.baidu.com:8235/baidu/mbd-sqa/cts"

print_success(){
  printf "\x1B[0;32m%s\n\x1B[0m" "$1"
}

print_faile(){
  printf "\x1B[0;31m%s\n\x1B[0m" "$1"
}

check_return() {
  value=$?
	if [ $value -ne 0 ]
	then
		print_faile "$1失败"
		exit 1
	else
		print_success "$1成功"
	fi
}

file_path=$ROOT_PATH/
if [ ! -d "$file_path" ]; then
  mkdir "$file_path"
fi

file_path=$ROOT_PATH/cts
echo "$file_path"
if [ -d "$file_path" ]; then
  echo "仓库存在，跳过克隆"
  exit 0
fi

if [ -z "$NAME" ]; then
    echo "请输入iCode用户名"
    echo "举例: ssh://yangtonggang@icode.baidu.com:8235/baidu/mbd-sqa/cts 则输入yangtonggang"
    read -r NAME
fi

cd "$ROOT_PATH" || exit
echo "开始克隆CTS仓库"
echo "$GIT_CLONE"
git clone "$GIT_CLONE"
check_return "克隆"

cd 'cts' || exit
echo "更新npm仓库，初始化等待时间可能较长，如果超过2分钟，请重新执行"
npm i --chromedriver_cdnurl=http://cdn.npm.taobao.org/dist/chromedriver
npm i --registry https://npm.taobao.org/mirrors/npm/
echo "百度的npm源较慢，做好准备等待 等待 .....~"
npm i --registry http://registry.npm.baidu-int.com
echo "项目依赖较多，假装更新完成😭，大胆往前走~"
echo '-'
