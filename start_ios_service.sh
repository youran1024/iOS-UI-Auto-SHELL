#!/usr/bin/env bash
: '
@File   : start_ios_service.sh
@Author : yangtonggang
@Date   : 2020-03-31
@Desc   : 初始化工程
'

UDID=$1
PORT=$2
LOG_PATH=$3

ROOT_PATH=~/cts-runner
WDA_PATH="$ROOT_PATH"/WebDriverAgent/WebDriverAgent.xcodeproj
URL_HOST="http://localhost:$PORT/status"


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

mk_dir(){
  dir_path=$1
  if [ ! -d "$dir_path" ]; then
    mkdir -p "$dir_path"
  fi
}

del_wda(){
  echo "删除 wda"
  isInstalled=$(ideviceinstaller -l | grep WebDriverAgentRunner)
  if [ -n "$isInstalled" ]; then
    ideviceinstaller -U com.layzui.test.xctrunner > /dev/null
    check_return '删除 wda'
    return 0
  fi
  echo "没有安装wda"
}

clear_process_sys(){
  # 清理系统级进程
  CMD_LINE="ps -A | grep -v grep | grep $1 | grep $2 | awk '{print \$1}' | xargs kill -9"
  echo "$CMD_LINE"
  bash -c "$CMD_LINE"
  check_return "关闭$1:$2服务"
}

clear_port_service(){
  CMD_LINE="lsof -i:$1 | awk 'NR>1{print \$2}' | xargs kill -9"
  bash -c "$CMD_LINE"
  check_return "关闭$1端口服务"
}

clear_service(){
  id="id=$UDID"
  # 清理xcodebuild 进程
  clear_process_sys xcodebuild "$id"
  # 清理当前设备可能占用的iproxy
  clear_process_sys iproxy "$UDID"
  # 清理被占用的端口号
  clear_port_service "$PORT"
}

clear_process(){
  CMD_LINE="ps -a | grep -v grep | grep $1 | grep $2 | awk '{print \$1}' | xargs kill -9"
  bash -c "$CMD_LINE"
  check_return "关闭$1:$2服务"
}

check_real_success(){
  retry_time=1
  while ((retry_time--)); do
    if ! check_wda_status; then
      return 1
    fi
    sleep 2
  done
  return 0
}

start_wda(){
  xcode_log="$1"/xcodebuild-"$2".log

  if ! [ -x "$WDA_PATH" ]; then
      print_faile "文件不存在：$WDA_PATH"
      exit 1
  fi
  # echo "xcodebuild -scheme WebDriverAgentRunner -destination \"id=$UDID\" -project \"$WDA_PATH\" test"
  echo "xcodebuild -scheme WebDriverAgentRunner -destination id=$UDID -project $WDA_PATH test > $xcode_log 2>&1 &"
  for (( i = 1; i <= 3; i = i + 1 ))
  do
    if ((i == 2)); then
      # clear_service
      # 清理xcodebuild 进程
      clear_process_sys xcodebuild "$id"
      del_wda
    fi
    echo "start wda service"

    bash_file="$ROOT_PATH"/wda
    echo "nohup xcodebuild -scheme WebDriverAgentRunner -destination \"id=$UDID\" -project \"$WDA_PATH\" test > \"$xcode_log\" 2>&1 &" > "$bash_file"
    chmod 777 "$bash_file"
    bash -c "open -a Terminal.app $bash_file"

    # nohup xcodebuild -scheme WebDriverAgentRunner -destination "id=$UDID" -project "$WDA_PATH" test > "$xcode_log" 2>&1 &

    rety_time=60
    sleep_time=1s
    while ((rety_time > 0))
    do
      echo "$"
      if check_wda_status '#'; then
        break
      fi
      ((rety_time--))
      sleep $sleep_time
    done
    if check_real_success; then
      return 0
    else
      # 清理xcodebuild 进程
      clear_process_sys xcodebuild "$id"
    fi
    echo '#'
  done
  print_faile '服务启动失败'
  exit 1
}

start_proxy(){
  echo "start proxy service"
  iproxy_log="$1"/iproxy.log
  value=$(iproxy -h | grep 'iproxy LOCAL_TCP_PORT DEVICE_TCP_PORT \[UDID\]')
  if [ -n "$value" ]; then
    iproxy "$PORT" "8100" "$UDID" > "$iproxy_log" 2>&1 &
  else
    echo "iproxy $PORT:8100 -u $UDID "
    iproxy "$PORT:8100" -u "$UDID" > "$iproxy_log" 2>&1 &
  fi

  print_success "start proxy success"
}

check_wda_status(){
  key=$1
  value=$(curl --connect-timeout 5 -m 10 --no-keepalive --no-buffer "$URL_HOST" -s | grep sessionId)
  if [ -n "$value" ]; then
    if [ -n "$key" ]; then
      echo "$key"
    fi
    echo "$value"
    return 0
  fi
  return 1
}

check_service(){
  if check_wda_status ''; then
    print_success "启动成功"
    return 0
  fi
  return 1
}

start(){
  time=$(date '+%Y-%m-%d %H:%M')
  log_dir="$LOG_PATH"/WdaService
  mk_dir "$log_dir"

  echo "-------------- 启动服务 --------------"
  echo "$@"
  # 服务状态检查
  if check_service  "$log_dir" "$time"; then
    exit 0
  fi

  clear_service
  start_proxy "$log_dir" "$time"
  start_wda "$log_dir" "$time"
}

start "$@"

