# iOS_UI_Auto

> iOS的环境安装相对较为复杂，提供了一键安装脚本。
> 脚本中包含其它能力，未做删除，故仅交流学习使用

### 关键字
`shell` `ideviceinstaller` `wda`

```bash
#!/usr/bin/env bash
: '
@File   : init.sh
@Desc   : 初始化工程
'

ROOT_PATH=~/cts-runner
CURRENT_PATH=$(cd "$(dirname "$0")" && pwd)
RESOURCE="$CURRENT_PATH"/../Resource/
LIB_LOCATION="/usr/local/lib/node_modules/"

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

is_install(){
  if [ -x "$(command -v "$1")" ]; then
    return 0
  fi
  return 1
}

f_install(){
  echo "👨‍💻 正在检查 ==> $1"
  if ! is_install "$1"; then
  	echo "😝 正在安装 ==> $1"
  	if [ "$3" == 1 ]; then
  	  pip3 install "$2"
  	elif [ "$3" == 2 ]; then
  	  brew install "$2"
  	elif [ "$3" == 3 ]; then
      npm --registry  https://registry.npm.taobao.org install -g "$2"
  	else
  	  echo "$2"
  	  ($2)
  	fi

    if is_install "$1"; then
      print_success "😃 安装成功 ==> $1"
    else
      print_faile "😂 安装失败 ==> $1"
    fi
  else
    print_success "😃 已经安装 ==> $1"
  fi
}

pip_install(){
  f_install "$1" "$2" 1
}

brew_install(){
  f_install "$1" "$2" 2
}

npm_install(){
  f_install "$1" "$2" 3
}

direct_install(){
  f_install "$1" "$2" 4
}

f_easy_install(){
  f_install "$1" easy_install 1
}

_install_brew(){
  # https://juejin.im/post/5c738bacf265da2deb6aaf97
  print_faile "brew 建议使用镜像安装"
  # ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

_install_pip(){
  print_faile '安装pip3，请输入电脑登录密码'
  sudo easy_install pip3
}

install_lib_mobile_device(){
    brew uninstall ideviceinstaller
    brew uninstall libimobiledevice
    brew install --HEAD libimobiledevice
    brew link --overwrite libimobiledevice
    brew install --HEAD ideviceinstaller
    brew link --overwrite ideviceinstaller
}

_install_npm_package(){
  if [ ! -e "$LIB_LOCATION$1" ]; then
    echo "安装：$1"
    sudo npm --registry https://registry.npm.taobao.org install -g "$1" > /dev/null
    check_return "安装：$1"
  fi
}

_install_npm_package_tb(){
  # https://developer.aliyun.com/mirror/NPM
  # https://npm.taobao.org/mirrors/npm/
  if [ ! -e "$LIB_LOCATION$1" ]; then
    echo "安装：$1"
    sudo npm --registry http://npm.taobao.org/mirrors/chromedriver install -g "$1" > /dev/null
    check_return "安装：$1"
  fi
}

_install_npm_chromedriver(){
  if [ ! -e "$LIB_LOCATION$1" ]; then
    echo "安装：$1"
    sudo npm --chromedriver_cdnurl=http://cdn.npm.taobao.org/dist/chromedriver install -g chromedriver > /dev/null
    check_return "安装：$1"
  fi
}

install_npm_package(){
  _install_npm_package 'bat-agent'
  _install_npm_package 'mocha'
  _install_npm_package 'mochawesome'
#   _install_npm_package_tb 'chromedriver'
#  _install_npm_chromedriver 'chromedriver'
}

_pip_install(){
  echo "安装 $1"
  cmd="sudo pip3 install $1 -i http://pypi.douban.com/simple/ --trusted-host pypi.douban.com"
  bash -c "$cmd" > /dev/null
  check_return "安装 $1"
}

pip_install_all(){
  _pip_install -U\ facebook-wda
  if [ -e /Applications/iTerm.app ]; then
    _pip_install imgcat
  fi
}

check_git_repo(){
  file_path=$ROOT_PATH/cts
  echo "$file_path"
  if [ ! -d "$file_path" ]; then
    echo "仓库不存在：$file_path"
    echo "需要初始化仓库"
    echo "请输入本地仓库路径, 没有则直接回车"
    read -r LOCAL_PATH
    if [ -n "$LOCAL_PATH" ]; then
        cd "$ROOT_PATH" || exit
        ln -s "$LOCAL_PATH" cts
        cd - || exit
    else
      echo "请输入github用户名"
      echo "举例: ssh://github 仓库地址"
      read -r NAME
    fi
  fi
}

install_package(){

  if ! is_install "xcodebuild"; then
    print_faile "👨‍💻 请先在AppStore安装xcode，安装完成后重新初始化"
    exit 1
  fi

  direct_install 'pip3' _install_pip
  if ! is_install "brew"; then
    print_faile "brew安装时，建议使用镜像安装, 安装完成后重新执行脚本"
    echo "参考方案："
    echo "https://juejin.im/post/5c738bacf265da2deb6aaf97"
    exit 1
  fi
  brew_install python3
  # f_install "brew" _install_brew 3
  direct_install 'idevice_id' install_lib_mobile_device
  brew_install 'iproxy' 'usbmuxd'
  brew_install 'carthage' 'carthage'

  pip_install_all

  install_npm_package

}

tar_wda(){
  # ROOT_PATH=~/cts-runnter
  echo "解压WebDriverAgent"
  file_path=$ROOT_PATH/
  if [ ! -d "$file_path" ]; then
    mkdir "$file_path"
  fi

  WDA_PATH="$RESOURCE"WebDriverAgent.zip
  # echo "$WDA_PATH"
  # tar zxvf "$WDA_PATH" -C "$file_path"/ > /dev/null 2>&1
  echo "解压中..."
  unzip -o "$WDA_PATH" -d "$file_path" > /dev/null
  check_return "解压WebDriverAgent"
}

start(){
  # git pull > /dev/null 2>&1
  if [ ! -d "$ROOT_PATH" ]; then
    mkdir "$ROOT_PATH"
  fi
  check_git_repo

  print_faile '安装期间，可能需要输入电脑登录密码'
  install_package

  tar_wda

  echo "安装证书"
  sh "$RESOURCE"/Certificates/install_prov_p12.sh
  check_return "证书安装"

  echo "安装命令行"
  cd "/usr/local/bin" || exit
  rm -rf cts
  # ln -s "$RESOURCE"/cts cts
  cp "$RESOURCE"/cts cts
  check_return "命令行安装"

  if [ -n "$NAME" ]; then
    echo "克隆仓库"
    sh "$CURRENT_PATH"/repo_init.sh "$NAME" "$ROOT_PATH"
    check_return "克隆仓库"
  fi
}

start
print_success "初始化完成"

```


## 总结
1. 希望能帮到你
2. 祝你好运
