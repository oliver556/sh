#!/bin/bash

# 脚本版本
sh_v="1.0.0"

# 重置颜色为白色
PLAIN='\033[0m'
# 红色
RED='\033[0;31m'
# 黄色
YELLOW='\033[0;33m'
# 绿色
GREEN='\033[0;32m'
# 天蓝色
SKYBLUE='\033[0;36m'
# 灰色
GREY='\e[37m'


# 复制将当前目录下的 leon.sh 文件复制到 /usr/local/bin 目录，并将其重命名为 n。
# 复制过程中所有的输出信息和错误信息都被重定向到 /dev/null，因此不会在终端显示任何输出。这通常用于静默执行命令，避免输出干扰。
cp ./leon.sh /usr/local/bin/n > /dev/null 2>&1

# 函数：提示用户按任意键继续
break_end() {
	echo -e "${GREEN}操作完成${PLAIN}"
	echo "按任意键继续..."
	read -n 1 -s -r -p ""
	echo ""
	clear
}

# 函数：重头执行函数
leon() {
	n
	exit
}

# 获取服务器 IPV4、IPV6 公网地址
ip_address() {
  ipv4_address=$(curl -s ipv4.ip.sb)
  ipv6_address=$(curl -s --max-time 1 ipv6.ip.sb)
}

# 函数：获取服务器流量统计状态，格式化输出（单位保留 GB）
output_status() {
  output=$(awk 'BEGIN { rx_total = 0; tx_total = 0 }
		NR > 2 { rx_total += $2; tx_total += $10 }
		END {
			rx_units = "Bytes";
			tx_units = "Bytes";
			if (rx_total > 1024) { rx_total /= 1024; rx_units = "KB"; }
			if (rx_total > 1024) { rx_total /= 1024; rx_units = "MB"; }
			if (rx_total > 1024) { rx_total /= 1024; rx_units = "GB"; }

			if (tx_total > 1024) { tx_total /= 1024; tx_units = "KB"; }
			if (tx_total > 1024) { tx_total /= 1024; tx_units = "MB"; }
			if (tx_total > 1024) { tx_total /= 1024; tx_units = "GB"; }

			printf("总接收: %.2f %s\n总发送: %.2f %s\n", rx_total, rx_units, tx_total, tx_units);
		}' /proc/net/dev)
}

# 函数：系统更新
linux_update() {
    # Update system on Debian-based systems
    if [ -f "/etc/debian_version" ]; then
				apt update -y && DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
    fi

    # Update system on Red Hat-based systems
    if [ -f "/etc/redhat-release" ]; then
				yum -y update
    fi

    # Update system on Alpine Linux
    if [ -f "/etc/alpine-release" ]; then
        apk update && apk upgrade
    fi

}

# 函数：清理不同 Linux 发行版（Debian、Red Hat、Alpine）系统的函数。它根据系统版本使用不同的清理命令，
# 包括清理软件包缓存、日志和内核文件，以释放磁盘空间。
linux_clean() {

	# 清理 Debian 系统
	clean_debian() {
		# 自动删除不需要的软件包，并清理相关的配置文件
		apt autoremove --purge -y
		# 清理下载的软件包的缓存
		apt clean -y
		# 清理旧的软件包下载缓存
		apt autoclean -y
		# 移除已经标记为删除但未完全清理的软件包
		apt remove --purge $(dpkg -l | awk '/^rc/ {print $2}') -y
		# 旋转系统日志
		journalctl --rotate
		# 清理老旧的系统日志，保留不超过1秒的日志
		journalctl --vacuum-time=1s
		# 清理系统日志，保留不超过50MB的日志
		journalctl --vacuum-size=50M
		# 移除旧的 Linux 内核镜像和头文件
		apt remove --purge $(dpkg -l | awk '/^ii linux-(image|headers)-[^ ]+/{print $2}' | grep -v $(uname -r | sed 's/-.*//') | xargs) -y
	}

	# 清理 Red Hat 系统
	clean_redhat() {
		# 自动删除不需要的软件包
		yum autoremove -y
		# 清理 YUM 软件包管理器的缓存
		yum clean all
		# 旋转系统日志
		journalctl --rotate
		# 清理老旧的系统日志，保留不超过1秒的日志
		journalctl --vacuum-time=1s
		# 清理系统日志，保留不超过50MB的日志
		journalctl --vacuum-size=50M
		# 移除旧的内核
		yum remove $(rpm -q kernel | grep -v $(uname -r)) -y
	}

	# 清理 Alpine Linux 系统
	clean_alpine() {
		# 移除不再需要的安装包
		apk del --purge $(apk info --installed | awk '{print $1}' | grep -v $(apk info --available | awk '{print $1}'))
		# 自动移除不需要的软件包
		apk autoremove
		# 清理 APK 软件包管理器的缓存
		apk cache clean
		# 移除日志文件
		rm -rf /var/log/*
		# 清理 APK 的缓存文件
		rm -rf /var/cache/apk/*
	}

	# Main script
	if [ -f "/etc/debian_version" ]; then
		# Debian-based systems
		clean_debian
	elif [ -f "/etc/redhat-release" ]; then
		# Red Hat-based systems
		clean_redhat
	elif [ -f "/etc/alpine-release" ]; then
		# Alpine Linux
		clean_alpine
	fi
}

# 函数：启用 BBR 拥塞控制算法
bbr_on() {
# 将以下内容覆盖写入 /etc/sysctl.conf 文件中
cat > /etc/sysctl.conf << EOF
net.core.default_qdisc=fq_pie
net.ipv4.tcp_congestion_control=bbr
EOF
# 重新加载
sysctl -p
}

# 函数：判断服务器系统类型
detect_system() {
	if [ -f /etc/os-release ]; then
		. /etc/os-release
		if [ "$ID" = "debian" ] || [ "$ID" = "ubuntu" ]; then
			echo "This is a Debian or Ubuntu based system"
		elif [ "$ID" = "centos" ]; then
			echo "This is a CentOS based system"
		else
			echo "Unknown distribution"
			exit 1
		fi
	elif [ -f /etc/debian_version ]; then
		echo "This is a Debian based system"
	elif [ -f /etc/redhat-release ]; then
		echo "This is a CentOS based system"
	else
		echo "Unknown distribution"
		exit 1
	fi
}

# 函数：speedtest 测速工具
speed_test_tool() {
	# 判断系统类型
	detect_system

	# Debian、Ubuntu
	if [ "$ID" = "debian" ] || [ "$ID" = "ubuntu" ]; then
		# 检查 curl 是否已安装
		if ! command -v curl &> /dev/null; then
			echo "curl 未安装，开始安装..."
			# 安装 curl
			sudo apt-get install curl
		fi

		# 使用 curl 安装 speedtest-cli
		if ! command -v speedtest-cli &> /dev/null
		then
				curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
		fi

		# 检查 speedtest 是否已安装
		if ! command -v speedtest &> /dev/null; then
				clear
				echo "speedtest 未安装，开始安装..."
				# 安装 speedtest
				sudo sudo apt-get install speedtest
				echo ""
				echo "------------------------"
				echo "安装已完成"
				echo "运行 speedtest 来进行测试"
		else
				# 如果已安装，直接运行 speedtest
				clear
				echo ""
				echo "------------------------"
				echo "正在运行 Speedtest"
				speedtest
		fi
	fi

	# Centos
	if [ "$ID" = "centos" ]; then
  		# 使用 curl 安装 speedtest-cli
  		if ! command -v speedtest-cli &> /dev/null; then
				curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh | sudo bash
  		fi

  		# 检查 speedtest 是否已安装
  		if ! command -v speedtest &> /dev/null; then
  				clear
  				echo "speedtest 未安装，开始安装..."
  				# 安装 speedtest
  				sudo sudo yum install speedtest
  				echo ""
  				echo "------------------------"
  				echo "安装已完成"
  				echo "运行 speedtest 来进行测试"
  		else
  				# 如果已安装，直接运行 speedtest
  				clear
  				echo ""
  				echo "------------------------"
  				echo "正在运行 Speedtest"
  				speedtest
  		fi
  	fi

}

# 函数：安装更新 Docker 环境
install_add_docker() {
	#  Alpine Linux 使用 apk 包管理器进行安装
	if [ -f "/etc/alpine-release" ]; then
		# 更新包管理器并安装 Docker
		apk update
		# 更新包管理器并安装 Docker Compose
		apk add docker docker-compose
		# 将 Docker 添加到默认的启动项
		rc-update add docker default
		# 启动 Docker
		service docker start
	else
		curl -fsSL https://get.docker.com | sh && ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin
		systemctl start docker
		systemctl enable docker
	fi

	sleep 2
}

# 函数：是否以 root 用户身份运行
root_use() {
	clear
	[ "$EUID" -ne 0 ] && echo -e "${RED}请注意，该功能需要 root 用户 才能运行！${PLAIN}" && break_end && leon
}

# 函数：设置允许 ROOT 用户通过 SSH 登录，并设置 ROOT 用户的密码
add_root_ssh() {
	echo "设置你的 ROOT 密码"
	# 提示用户输入两次密码，用于设置 ROOT 用户的密码
	passwd
	# 修改 /etc/ssh/sshd_config 文件来允许 ROOT 用户通过 SSH 登录
	sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
	# 修改 /etc/ssh/sshd_config 文件来允许密码进行认证
	sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
	# 清理 SSH 配置目录下的临时文件
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	# 函数：根据系统中安装的包管理器来使用适当的命令来重启 SSH 服务
	restart_ssh
	# 显示消息，表示 ROOT 登录设置完成
	echo -e "${GREEN}ROOT登录设置完毕！${PLAIN}"
	# 函数：询问用户是否要重启服务器
	server_reboot
}

# 函数：根据系统中安装的包管理器来使用适当的命令来重启 SSH 服务
restart_ssh() {
	if command -v dnf &>/dev/null; then
		systemctl restart sshd
	elif command -v yum &>/dev/null; then
		systemctl restart sshd
	elif command -v apt &>/dev/null; then
		service ssh restart
	elif command -v apk &>/dev/null; then
		service sshd restart
	else
		echo "无法找到SSH服务启动脚本，无法重启SSH服务!"
		return 1
	fi
}

# 函数：询问用户是否要重启服务器
server_reboot() {
	# 输入是否要重启服务器，用户可以输入 "Y" 或 "N" 来回答
	read -p "$(echo -e "${YELLOW}现在重启服务器吗？(Y/N): ${PLAIN}")" rboot
	case "$rboot" in
		[Yy])
			echo "已重启"
			reboot
			;;
		[Nn])
			echo "已取消"
			;;
		*)
			echo "无效的选择，请输入 Y 或 N。"
			;;
	esac
}

# 函数：开放所有端口
open_all_ports() {
	# iptables 和 ip6tables 的默认策略设置为接受（ACCEPT），并清空所有防火墙规则，

	iptables -P INPUT ACCEPT
	iptables -P FORWARD ACCEPT
	iptables -P OUTPUT ACCEPT
	iptables -F

	ip6tables -P INPUT ACCEPT
	ip6tables -P FORWARD ACCEPT
	ip6tables -P OUTPUT ACCEPT
	ip6tables -F
}

# 函数：修改 SSH 连接端口
new_ssh_port() {
	# 备份 SSH 配置文件
	cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

	# 使用 sed 替换命令将原先注释掉的端口配置取消注释，即将 #Port 改为 Port
	sed -i 's/^\s*#\?\s*Port/Port/' /etc/ssh/sshd_config

	# 将 sshd_config 文件中的原 SSH 端口号替换为新的端口号 $new_port
	sed -i "s/Port [0-9]\+/Port $new_port/g" /etc/ssh/sshd_config

	# 重启 SSH 服务
	service sshd restart

	# 打印消息，确认 SSH 端口已被成功修改
	echo "SSH 端口已修改为: $new_port"

	clear
	# 调用函数以打开所有端口
	open_all_ports

	# 移除一些防火墙相关的软件
	remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
}

# 函数：配置 DNS 解析器
configure_dns_resolvers() {
	# 定义 Cloudflare、Google 的 IPv4 和 IPv6 DNS 地址
	cloudflare_ipv4="1.1.1.1"
	google_ipv4="8.8.8.8"
	cloudflare_ipv6="2606:4700:4700::1111"
	google_ipv6="2001:4860:4860::8888"

	# 检查机器是否有 IPv6 地址（存在即支持）
	ipv6_available=0
	if [[ $(ip -6 addr | grep -c "inet6") -gt 0 ]]; then
		ipv6_available=1
	fi

	# 设置 DNS 地址为 Cloudflare 和 Google（IPv4 和 IPv6）
	echo "设置 DNS 为 Cloudflare 和 Google"

	# 设置 IPv4 地址
	echo "nameserver $cloudflare_ipv4" > /etc/resolv.conf
	echo "nameserver $google_ipv4" >> /etc/resolv.conf

	# 如果有 IPv6 地址，则设置 IPv6 地址
	if [[ $ipv6_available -eq 1 ]]; then
		echo "nameserver $cloudflare_ipv6" >> /etc/resolv.conf
		echo "nameserver $google_ipv6" >> /etc/resolv.conf
	fi

	echo -e "${GREEN}DNS 地址已更新${PLAIN}"
	echo "------------------------"
	cat /etc/resolv.conf
	echo "------------------------"

}

# 函数:重新配置系统的 swap 分区和文件。该函数删除所有现有的 swap 分区和文件，
# 并创建一个新的 swap 文件，将其配置为系统的 swap 空间。
add_swap() {
	# 获取当前系统中所有的 swap 分区
	swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')

	# 遍历并删除所有的 swap 分区
	for partition in $swap_partitions; do
		swapoff "$partition"
		# 清除文件系统标识符
		wipefs -a "$partition"
		mkswap -f "$partition"
	done

	# 确保 /swapfile 不再被使用
	swapoff /swapfile

	# 删除旧的 /swapfile
	rm -f /swapfile

	# 创建新的 swap 文件：
	dd if=/dev/zero of=/swapfile bs=1M count=$new_swap
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile

	# 更新系统配置文件
	if [ -f /etc/alpine-release ]; then
		echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
		echo "nohup swapon /swapfile" >> /etc/local.d/swap.start
		chmod +x /etc/local.d/swap.start
		rc-update add local
	else
		echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
	fi

	echo -e "虚拟内存大小已调整为${YELLOW}${new_swap}${PLAIN} MB"
}

# 函数：获取当前系统时区
current_timezone() {
	if grep -q 'Alpine' /etc/issue; then
	 :
	else
	 timedatectl show --property=Timezone --value
	fi
}

# 函数：重启服务器
restart_the_server() {
	read -p "$(echo -e "${YELLOW}现在重启服务器吗？(Y/N): ${PLAIN}")" rboot
	case "$rboot" in
		[Yy])
			echo "已重启"
			reboot
			;;
		[Nn])
			echo "已取消"
			;;
		*)
			echo "无效的选择，请输入 Y 或 N。"
			;;
	esac
}

while true; do
	clear

	echo -e "${GREEN}========================================================= "
	echo "_    ____  ____ _  _ "
	echo "|    |___  |  | |\ | "
	echo -e "|___ |___  |__| | \|   ${YELLOW}v$sh_v${PLAIN}"
	echo ""
	echo -e "${GREEN}Leon 一键脚本工具（支持 Ubuntu/Debian/CentOS/Alpine 系统）${PLAIN}"
	echo -e "${GREEN}输入${YELLOW} n ${GREEN}可快速启动此脚本 ${PLAIN}"
	echo -e "${GREEN}=========================================================${PLAIN}"
	echo ""
	echo "1. 系统信息查询"
	echo "2. 系统更新"
	echo "3. 系统清理"
	echo "4. 常用工具 ▶"
	echo "5. BBR 管理 ▶"
	echo "6. Docker 管理 ▶ "
	echo "8. 测试脚本合集 ▶ "
	echo "11. 面板工具 ▶ "
	echo "13. 系统工具 ▶ "
	echo "------------------------"
	echo "00. 脚本更新"
	echo "------------------------"
	echo "0. 退出脚本"
	echo "------------------------"
	read -p "请输入你的选择: " choice

	case $choice in
		# 信息系统查询
		1)
			clear
			# 执行函数：获取 IPv4 和 IPv6 地址
			ip_address

			# ------------------------
			# 获取主机名
			host_name=$(hostname)

			# 获取服务器 IP 地址所属的组织（如 ISP 或公司）(包含了关于 IP 地址的详细信息，包括组织、位置、ASN 等)
			isp_info=$(curl -s ipinfo.io/org)

			# ------------------------
			# 尝试使用 lsb_release 获取系统信息
			os_info=$(lsb_release -ds 2>/dev/null)
			# 如果 lsb_release 命令失败，则尝试其它方法
			if [ -z "$os_info" ]; then
				# 检查常见的发行文件
				if [ -f "/etc/os-release" ]; then
					os_info=$(source /etc/os-release && echo "$PRETTY_NAME")
					elif [ -f "/etc/debian_version" ]; then
						os_info="Debian $(cat /etc/debian_version)"
					elif [ -f "/etc/redhat-release" ]; then
						os_info=$(cat /etc/redhat-release)
					else
						os_info="Unknown"
					fi
				fi

			# 获取 Linux 版本
			kernel_version=$(uname -r)

			# ------------------------
			# 获取 CPU 架构
			cpu_arch=$(uname -m)

			# 获取 CPU 型号
			if [ "$(uname -m)" == "x86_64" ]; then
					cpu_info=$(cat /proc/cpuinfo | grep 'model name' | uniq | sed -e 's/model name[[:space:]]*: //')
			else
					cpu_info=$(lscpu | grep 'BIOS Model name' | awk -F': ' '{print $2}' | sed 's/^[ \t]*//')
			fi

			# 获取 CPU 核心数
			cpu_cores=$(nproc)

			# ------------------------
			# CPU 占用率
			if [ -f /etc/alpine-release ]; then
					# Alpine Linux 使用以下命令获取 CPU 使用率
					cpu_usage_percent=$(top -bn1 | grep '^CPU' | awk '{print " "$4}' | cut -c 1-2)
			else
					# 其他系统使用以下命令获取 CPU 使用率
					cpu_usage_percent=$(top -bn1 | grep "Cpu(s)" | awk '{print " "$2}')
			fi

			# 获取物理内存
			mem_info=$(free -b | awk 'NR==2{printf "%.2f/%.2f MB (%.2f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')

			# 获取虚拟物理内存
			swap_used=$(free -m | awk 'NR==3{print $3}')
			swap_total=$(free -m | awk 'NR==3{print $2}')

			if [ "$swap_total" -eq 0 ]; then
					swap_percentage=0
			else
					swap_percentage=$((swap_used * 100 / swap_total))
			fi

			swap_info="${swap_used}MB/${swap_total}MB (${swap_percentage}%)"

			# 获取硬盘占用
			disk_info=$(df -h | awk '$NF=="/"{printf "%s/%s (%s)", $3, $2, $5}')

			# ------------------------
			# 获取网络拥堵算法
			congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
			queue_algorithm=$(sysctl -n net.core.default_qdisc)

			# ------------------------
			# 获取地理位置 / 城市
			country=$(curl -s ipinfo.io/country)
			city=$(curl -s ipinfo.io/city)

			# 获取系统时间
			current_time=$(date "+%Y-%m-%d %I:%M %p")

			# 执行函数：
			output_status

			echo ""
			echo -e "${SKYBLUE}系统信息查询${PLAIN}"
			echo "------------------------"
			echo "主机名：$host_name"
			echo "运营商：$isp_info"
			echo "------------------------"
			echo "系统版本: $os_info"
			echo "Linux 版本: $kernel_version"
			echo "------------------------"
			echo "CPU 架构: $cpu_arch"
			echo "CPU 型号: $cpu_info"
			echo "CPU 核心数: $cpu_cores"
			echo "------------------------"
			echo "CPU 占用: $cpu_usage_percent%"
			echo "物理内存: $mem_info"
			echo "虚拟内存: $swap_info"
			echo "硬盘占用: $disk_info"
			echo "------------------------"
			echo "$output"
			echo "------------------------"
			echo "网络拥堵算法: $congestion_algorithm $queue_algorithm"
			echo "------------------------"
			echo "公网 IPv4 地址: $ipv4_address"
			echo "公网 IPv6 地址: $ipv6_address"
			echo "------------------------"
			echo "地理位置: $country $city"
			echo "系统时间: $current_time"
			echo "------------------------"
		;;

		# 系统更新
		2)
			clear
			linux_update
			;;

		# 系统清理
  	3)
			clear
			linux_clean
			;;

		# 常用工具
		4)
			while true; do
			 	clear
			 	echo "▶ 安装常用工具"
			 	echo "------------------------"
			 	echo "1. curl 下载工具"
			 	echo "2. wget 下载工具"
				echo "3. sudo 超级管理权限工具"
				echo "4. socat 通信连接工具 （申请域名证书必备）"
				echo "5. htop 系统监控工具"
				echo "6. iftop 网络流量监控工具"
				echo "7. unzip ZIP压缩解压工具"
				echo "8. tar GZ压缩解压工具"
				echo "9. tmux 多路后台运行工具"
				echo "10. ffmpeg 视频编码直播推流工具"
				echo "11. btop 现代化监控工具"
				echo "12. ranger 文件管理工具"
				echo "13. gdu 磁盘占用查看工具"
				echo "14. fzf 全局搜索工具"
				echo "15. speedtest™ 网络带宽测速"
				echo "------------------------"
				echo "21. cmatrix 黑客帝国屏保"
				echo "22. sl 跑火车屏保"
				echo "------------------------"
				echo "26. 俄罗斯方块小游戏"
				echo "27. 贪吃蛇小游戏"
				echo "28. 太空入侵者小游戏"
				echo "------------------------"
				echo "31. 全部安装"
				echo "32. 全部卸载"
				echo "------------------------"
				echo "41. 安装指定工具"
				echo "42. 卸载指定工具"
				echo "------------------------"
			 	echo "0. 返回主菜单"
				echo "------------------------"
				read -p "请输入你的选择: " sub_choice

				case $sub_choice in
					# curl 下载工具
					1)
						clear
						install curl
						clear
						echo "工具已安装，使用方法如下："
						curl --help
						;;

					# wget 下载工具
					2)
						clear
						install wget
						clear
						echo "工具已安装，使用方法如下："
						wget --help
						;;

					# sudo 超级管理权限工具
					3)
						clear
						install sudo
						clear
						echo "工具已安装，使用方法如下："
						sudo --help
						;;

					# socat 通信连接工具 （申请域名证书必备）
					4)
						clear
						install socat
						clear
						echo "工具已安装，使用方法如下："
						socat -h
						;;

					# htop 系统监控工具
					5)
						clear
						install htop
						clear
						htop
						;;

					# iftop 网络流量监控工具
					6)
						clear
						install iftop
						clear
						iftop
						;;

					# unzip ZIP压缩解压工具
					7)
						clear
						install unzip
						clear
						echo "工具已安装，使用方法如下："
						unzip
						;;

					# tar GZ压缩解压工具
					8)
						clear
						install tar
						clear
						echo "工具已安装，使用方法如下："
						tar --help
						;;

					# tmux 多路后台运行工具
					9)
						clear
						install tmux
						clear
						echo "工具已安装，使用方法如下："
						tmux --help
						;;

					# ffmpeg 视频编码直播推流工具
					10)
						clear
						install ffmpeg
						clear
						echo "工具已安装，使用方法如下："
						ffmpeg --help
						;;

					# btop 现代化监控工具
					11)
						clear
						install btop
						clear
						btop
						;;

					# ranger 文件管理工具
					12)
						clear
						install ranger
						cd /
						clear
						ranger
						cd ~
						;;

					# gdu 磁盘占用查看工具
					13)
						clear
						install gdu
						cd /
						clear
						gdu
						cd ~
						;;

					# fzf 全局搜索工具
					14)
						clear
						install fzf
						cd /
						clear
						fzf
						cd ~
						;;

					# speedtest Server network 网络测速工具
					15)
						clear
						speed_test_tool
						;;

					# ------------------------

					# cmatrix 黑客帝国屏保
					21)
						clear
						install cmatrix
						clear
						cmatrix
						;;

					# sl 跑火车屏保
					22)
						clear
						install sl
						clear
						/usr/games/sl
						;;

					# ------------------------

					# 俄罗斯方块小游戏
					26)
						clear
						install bastet
						clear
						/usr/games/bastet
						;;

					# 贪吃蛇小游戏
					27)
						clear
						install nsnake
						clear
						/usr/games/nsnake
						;;

					# 太空入侵者小游戏
					28)
						clear
						install ninvaders
						clear
						/usr/games/ninvaders
						;;

					# ------------------------

					# 全部安装
					31)
						clear
						install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger gdu fzf cmatrix sl bastet nsnake ninvaders
						;;

					# 全部卸载
					32)
						clear
						remove htop iftop unzip tmux ffmpeg btop ranger gdu fzf cmatrix sl bastet nsnake ninvaders
						;;

					# ------------------------

					# 安装指定工具
					41)
						clear
						read -p "请输入安装的工具名（wget curl sudo htop）: " installname
						install $installname
						;;

					# 卸载指定工具
					42)
						clear
						read -p "请输入卸载的工具名（htop ufw tmux cmatrix）: " removename
						remove $removename
						;;

					# ------------------------
					0)
						leon
						;;
					*)
						echo "无效的输入!"
						;;
				esac
					break_end
				done
			;;

		# BBR管理
		5)
			clear
			if [ -f "/etc/alpine-release" ]; then
				while true; do
					clear
					congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
					queue_algorithm=$(sysctl -n net.core.default_qdisc)
					echo "当前TCP阻塞算法: $congestion_algorithm $queue_algorithm"

					echo ""
					echo "BBR管理"
					echo "------------------------"
					echo "1. 开启BBRv3              2. 关闭BBRv3（会重启）"
					echo "------------------------"
					echo "0. 返回上一级选单"
					echo "------------------------"
					read -p "请输入你的选择: " sub_choice

					case $sub_choice in
						1)
							bbr_on
							;;
						2)
							sed -i '/net.core.default_qdisc=fq_pie/d' /etc/sysctl.conf
							sed -i '/net.ipv4.tcp_congestion_control=bbr/d' /etc/sysctl.conf
							sysctl -p
							reboot
							;;

						0)
							break  # 跳出循环，退出菜单
							;;

						*)
							break  # 跳出循环，退出菜单
							;;
					esac
				done

			else
				install wget
				wget --no-check-certificate -O tcpx.sh https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh
				chmod +x tcpx.sh
				./tcpx.sh
			fi
			;;

		# Docker 管理
		6)
			while true; do
				clear
				echo -e "${SKYBLUE}▶ Docker 管理器${PLAIN}"
				echo "------------------------"
				echo "1. 安装更新 Docker 环境"
				echo "------------------------"
				echo "2. 查看 Docker 全局状态"
				echo "------------------------"
				echo "3. Docker 容器管理 ▶"
				echo "4. Docker 镜像管理 ▶"
				echo "5. Docker 网络管理 ▶"
				echo "6. Docker 卷管理 ▶"
				echo "------------------------"
				echo "7. 清理无用的 Docker 容器和镜像网络数据卷"
				echo "------------------------"
				echo "8. 卸载 Docker 环境"
				echo "------------------------"
				echo "0. 返回主菜单"
				echo "------------------------"
				read -p "请输入你的选择: " sub_choice

				case $sub_choice in
					# 安装更新 Docker 环境
					1)
						clear
						install_add_docker
						;;

					# 查看 Docker 全局状态
					2)
						clear
						echo -e "${SKYBLUE}Docker 版本${PLAIN}"
						echo "------------------------"
						docker --version
						docker-compose --version
						echo ""
						echo -e "${SKYBLUE}Docker 镜像列表${PLAIN}"
						echo "------------------------"
						docker image ls
						echo ""
						echo -e "${SKYBLUE}Docker 容器列表${PLAIN}"
						echo "------------------------"
						docker ps -a
						echo ""
						echo -e "${SKYBLUE}Docker 卷列表${PLAIN}"
						echo "------------------------"
						docker volume ls
						echo ""
						echo -e "${SKYBLUE}Docker 网络列表${PLAIN}"
						echo "------------------------"
						docker network ls
						echo ""
						;;

					# Docker 容器管理
					# ToDo docker 容器管理未完成
					# 需求：查看（日志、网络）、创建、更新、重启、停止、删除，
					3)
						while true; do
							clear
							echo -e "${SKYBLUE}Docker 容器列表${PLAIN}"
							docker ps -a
							echo ""
							echo "容器操作"
							echo "------------------------"
							echo "1. 创建新的容器"
							echo "------------------------"
							echo "2. 启动指定容器             6. 启动所有容器"
							echo "3. 停止指定容器             7. 暂停所有容器"
							echo "4. 删除指定容器             8. 删除所有容器"
							echo "5. 重启指定容器             6. 重启所有容器"
							echo "------------------------"
							echo "11. 进入指定容器           12. 查看容器日志           13. 查看容器网络"
							echo "------------------------"
							echo "0. 返回上一级选单"
							echo "------------------------"
							read -p "请输入你的选择: " sub_choice

							case $sub_choice in
								# 创建新的容器
								1)
									read -p "请输入创建命令：" docker_name
									$docker_name
									;;

								#

								0)
									break  # 跳出循环，退出菜单
									;;
								*)
									break  # 跳出循环，退出菜单
									;;

								esac

							done
						;;

					0)
						leon
						;;
					*)
						echo "无效的输入!"
						;;
				esac
					break_end
			done
			;;

		# 测试脚本合集
		8)
			while true;do
				clear
				echo
				echo "▶ 测试脚本合集"
				echo ""
				echo "----IP及解锁状态检测-----------"
				echo "1. ChatGPT 解锁状态检测"
				echo "2. Region 流媒体解锁测试"
				echo ""
				echo "------------------------"
				echo "0. 返回主菜单"
				echo "------------------------"
				read -p "请输入你的选择: " sub_choice

				case $sub_choice in
					# ChatGPT 解锁状态检测
					1)
						clear
						bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
						;;

					# Region 流媒体解锁测试
					2)
						clear
						bash <(curl -L -s check.unlock.media)
						;;
					0)
						leon
						;;
					*)
						echo "无效的输入!"
						;;

				esac
					break_end
				done
			;;

		# 系统工具
		13)
			while true; do
				clear
				echo -e "${SKYBLUE}▶ 系统工具${PLAIN}"
				echo "------------------------"
				echo "1. 设置脚本启动快捷键"
				echo "------------------------"
				echo "2. 修改登录密码"
				echo "3. ROOT 密码登录模式"
				echo "4. 安装 Python 最新版"
				echo "5. 开放所有端口"
				echo "6. 修改 SSH 连接端口"
				echo "7. 优化 DNS 地址"
				echo "8. 一键重装系统"
				echo "9. 禁用 ROOT，并创建新账户赋 sudo"
				echo "10. 切换优先 ipv4/ipv6"
				echo "11. 查看端口占用状态"
				echo "12. 修改虚拟内存大小"
				echo "13. 用户管理"
				echo "14. 用户/密码生成器"
				echo "15. 系统时区调整"
				echo "16. 设置 BBR3 加速"
				echo "17. 防火墙高级管理器"
				echo "18. 修改主机名"
				echo "19. 切换系统更新源"
				echo "20. 定时任务管理"
				echo "21. 本机host解析"
				echo "22. fail2banSSH 防御程序"
				echo "23. 限流自动关机"
				echo "24. ROOT 私钥登录模式"
				echo "------------------------"
				echo "99. 重启服务器"
				echo "------------------------"
				echo "0. 返回主菜单"
				echo "------------------------"
				read -p "请输入你的选择: " sub_choice

				case $sub_choice in
					# 设置脚本启动快捷键
					1)
						clear
						read -p "请输入你的快捷按键: " shortcut_keys
						echo "alias $shortcut_keys='~/leon.sh'" >> ~/.bashrc
						source ~/.bashrc
						echo "快捷键已设置"
						;;

					# 修改登录密码
					2)
						clear
						echo "设置你的登录密码"
						passwd
						;;

					# ROOT 密码登录模式
					3)
						root_use
						add_root_ssh
						;;

					# 安装 Python 最新版
					4)
						root_use

						# 系统检测
						OS=$(cat /etc/os-release | grep -o -E "Debian|Ubuntu|CentOS" | head -n 1)
					 	if [[ $OS == "Debian" || $OS == "Ubuntu" || $OS == "CentOS" ]]; then
							echo -e "检测到你的系统是 ${YELLOW}${OS}${PLAIN}"
								else
							echo -e "${RED}很抱歉，你的系统不受支持！${PLAIN}"
								exit 1
						fi

						# 检测安装 Python3 的版本
						VERSION=$(python3 -V 2>&1 | awk '{print $2}')

						# 获取最新 Python3 版本
						PY_VERSION=$(curl -s https://www.python.org/ | grep "downloads/release" | grep -o 'Python [0-9.]*' | grep -o '[0-9.]*')

						# 卸载 Python3 旧版本
						if [[ $VERSION == "3"* ]]; then
							echo -e "${YELLOW}你的 Python3 版本是${PLAIN}${RED}${VERSION}${PLAIN}，${YELLOW}最新版本是${PLAIN}${RED}${PY_VERSION}${PLAIN}"
							read -p "是否确认升级最新版 Python3？默认不升级 [y/N]: " CONFIRM

							if [[ $CONFIRM == "y" ]]; then
								if [[ $OS == "CentOS" ]]; then
									echo ""
									rm-rf /usr/local/python3* >/dev/null 2>&1
								else
									apt --purge remove python3 python3-pip -y
									rm-rf /usr/local/python3*
								fi
							else
								echo -e "${YELLOW}已取消升级 Python3${PLAIN}"
								exit 1
							fi
						else
							echo -e "${RED}检测到没有安装 Python3。${PLAIN}"
							read -p "是否确认安装最新版 Python3？默认安装 [Y/n]: " CONFIRM
							if [[ $CONFIRM != "n" ]]; then
								echo -e "${GREEN}开始安装最新版 Python3...${PLAIN}"
							else
								echo -e "${YELLOW}已取消安装 Python3${PLAIN}"
								exit 1
							fi
						fi

						# 安装相关依赖
						if [[ $OS == "CentOS" ]]; then
							yum update
							yum groupinstall -y "development tools"
							yum install wget openssl-devel bzip2-devel libffi-devel zlib-devel -y
						else
							apt update
							apt install wget build-essential libreadline-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev -y
						fi

						# 安装 python3
						cd /root/
						wget https://www.python.org/ftp/python/${PY_VERSION}/Python-"$PY_VERSION".tgz
						tar -zxf Python-${PY_VERSION}.tgz
						cd Python-${PY_VERSION}
						./configure --prefix=/usr/local/python3
						make -j $(nproc)
						make install
						if [ $? -eq 0 ];then
							rm -f /usr/local/bin/python3*
							rm -f /usr/local/bin/pip3*
							ln -sf /usr/local/python3/bin/python3 /usr/bin/python3
							ln -sf /usr/local/python3/bin/pip3 /usr/bin/pip3
							clear
							echo -e "${YELLOW}Python3 安装${GREEN}成功，${PLAIN}版本为: ${PLAIN}${GREEN}${PY_VERSION}${PLAIN}"
						else
							clear
							echo -e "${RED}Python3 安装失败！${PLAIN}"
							exit 1
						fi
						cd /root/ && rm -rf Python-${PY_VERSION}.tgz && rm -rf Python-${PY_VERSION}

						;;

					# 开放所有端口
					5)
						root_use
						open_all_ports
						remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
						echo -e "${GREEN}端口已全部开放${PLAIN}"
						;;

					# 修改 SSH 连接端口
					6)
						root_use

						# 去掉 # Port 的注释
						sed -i 's/#Port/Port/' /etc/ssh/sshd_config

						# 读取当前的 SSH 端口号
            current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

            # 打印当前的 SSH 端口号
            echo "当前的 SSH 端口号是: $current_port"

            echo "------------------------"

            # 提示用户输入新的 SSH 端口号
            read -p "请输入新的 SSH 端口号: " new_port

            new_ssh_port
						;;

					# 优化 DNS 地址
					7)
						root_use
						echo -e "${SKYBLUE}当前 DNS 地址${PLAIN}"
						echo "------------------------"
						cat /etc/resolv.conf
						echo "------------------------"
						echo ""
						# 询问用户是否要优化 DNS 设置
						read -p "是否要设置为 Cloudflare 和 Google 的 DNS 地址？(y/n): " choice

						if [ "$choice" == "y" ]; then
							# 配置 DNS 解析器
							configure_dns_resolvers
						else
							echo "DNS 设置未更改"
						fi
						;;

					# 一键重装系统
					8)

						dd_xitong_2() {
							echo -e "任意键继续，重装后初始用户名: ${YELLOW}root${PLAIN}  初始密码: ${YELLOW}LeitboGi0ro${PLAIN}  初始端口: ${YELLOW}22${PLAIN}"
							read -n 1 -s -r -p ""
							install wget
							wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh
						}

						dd_xitong_3() {
							echo -e "任意键继续，重装后初始用户名: ${YELLOW}Administrator${PLAIN}  初始密码: ${YELLOW}Teddysun.com${PLAIN}  初始端口: ${YELLOW}3389${PLAIN}"
							read -n 1 -s -r -p ""
							install wget
							wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh
						}

						dd_xitong_4() {
							echo -e "任意键继续，重装后初始用户名: ${YELLOW}Administrator${PLAIN}  初始密码: ${YELLOW}123@@@${PLAIN}  初始端口: ${YELLOW}3389${PLAIN}"
							read -n 1 -s -r -p ""
							install wget
							curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
						}

						root_use
						echo -e "${RED}请备份数据${PLAIN}，将为你重装系统，预计花费 15 分钟。"
						echo -e "${GREY}感谢 MollyLau 的脚本支持！${PLAIN}"
						read -p "确定继续吗？(Y/N): " choice

						case "$choice" in
							[Yy])
								while true; do

									echo "------------------------"
									echo "1. Debian 12"
									echo "2. Debian 11"
									echo "3. Debian 10"
									echo "4. Debian 9"
									echo "------------------------"
									echo "11. Ubuntu 24.04"
									echo "12. Ubuntu 22.04"
									echo "13. Ubuntu 20.04"
									echo "14. Ubuntu 18.04"
									echo "------------------------"
									echo "21. CentOS 9"
									echo "22. CentOS 8"
									echo "23. CentOS 7"
									echo "------------------------"
									echo "31. Alpine 3.19"
									echo "------------------------"
									echo "41. Windows 11"
									echo "42. Windows 10"
									echo "43. Windows 7"
									echo "44. Windows Server 2022"
									echo "45. Windows Server 2019"
									echo "46. Windows Server 2016"
									echo "------------------------"
									read -p "请选择要重装的系统: " sys_choice

									case "$sys_choice" in
										# Debian 12
										1)
											dd_xitong_2
											bash InstallNET.sh -debian 12
											reboot
											exit
											;;

										# Debian 11
										2)
											dd_xitong_2
											bash InstallNET.sh -debian 11
											reboot
											exit
											;;

										# Debian 10
										3)
											dd_xitong_2
											bash InstallNET.sh -debian 10
											reboot
											exit
											;;

										# Debian 9
										4)
											dd_xitong_2
											bash InstallNET.sh -debian 9
											reboot
											exit
											;;

										# Ubuntu 24.04
										11)
											dd_xitong_2
											bash InstallNET.sh -ubuntu 24.04
											reboot
											exit
											;;

										# Ubuntu 22.04
										12)
											dd_xitong_2
											bash InstallNET.sh -ubuntu 22.04
											reboot
											exit
											;;

										# Ubuntu 20.04
										13)
											dd_xitong_2
											bash InstallNET.sh -ubuntu 20.04
											reboot
											exit
											;;

										# Ubuntu 18.04
										14)
											dd_xitong_2
											bash InstallNET.sh -ubuntu 18.04
											reboot
											exit
											;;

										# CentOS 9
										21)
											dd_xitong_2
											bash InstallNET.sh -centos 9
											reboot
											exit
											;;

										# CentOS 8
										22)
											dd_xitong_2
											bash InstallNET.sh -centos 8
											reboot
											exit
											;;

										# CentOS 7
										23)
											dd_xitong_2
											bash InstallNET.sh -centos 7
											reboot
											exit
											;;

										# Alpine 3.19
										31)
											dd_xitong_2
											bash InstallNET.sh -alpine
											reboot
											exit
											;;

										# 41. Windows 11
										41)
											dd_xitong_3
											bash InstallNET.sh -windows 11 -lang "cn"
											reboot
											exit
											;;

										# 41. Windows 10
										42)
											dd_xitong_3
											bash InstallNET.sh -windows 10 -lang "cn"
											reboot
											exit
											;;

										# 41. Windows 7
										43)
											dd_xitong_4
											bash reinstall.sh windows --image-name 'Windows 7 Professional' --lang zh-cn
											reboot
											exit
											;;

										# Windows Server 2022
										44)
											dd_xitong_4
											bash reinstall.sh windows --image-name 'Windows Server 2022 SERVERDATACENTER' --lang zh-cn
											reboot
											exit
											;;

										# Windows Server 2019
										45)
											dd_xitong_3
											bash InstallNET.sh -windows 2019 -lang "cn"
											reboot
											exit
											;;

										# Windows Server 2016
										46)
											dd_xitong_3
											bash InstallNET.sh -windows 2016 -lang "cn"
											reboot
											exit
											;;

										*)
											echo "无效的选择，请重新输入"
											;;
									esac

								done
								;;

							[Nn])
								echo "已取消"
								;;

							*)
								echo "无效的选择，请输入 Y 或 N。"
								;;

						esac
					;;

					# 禁用 ROOT，并创建新账户赋 sudo
					9)
						root_use

						# 提示用户输入新用户名
						read -p "请输入新用户名: " new_username

						# 创建新用户并设置密码
						useradd -m -s /bin/bash "$new_username"
						passwd "$new_username"

						# 赋予新用户 sudo 权限
						echo "$new_username ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers

						# 禁用 ROOT 用户登录
						passwd -l root

						echo "操作已完成。"
						;;

					# 切换优先 ipv4/ipv6
					10)
						root_use

						ipv6_disabled=$(sysctl -n net.ipv6.conf.all.disable_ipv6)

						echo ""
							if [ "$ipv6_disabled" -eq 1 ]; then
								echo "当前网络优先级设置: IPv4 优先"
							else
								echo "当前网络优先级设置: IPv6 优先"
							fi

						echo "------------------------"

						echo ""
						echo "切换的网络优先级"
						echo "------------------------"
						echo "1. IPv4 优先          2. IPv6 优先"
						echo "------------------------"
						read -p "选择优先的网络: " choice

						case $choice in
							1)
								sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null 2>&1
								echo "已切换为 IPv4 优先"
								;;
							2)
								sysctl -w net.ipv6.conf.all.disable_ipv6=0 > /dev/null 2>&1
								echo "已切换为 IPv6 优先"
								;;
							*)
								echo "无效的选择"
								;;
						esac

						;;

					# 查看端口占用状态
					11)
						clear
						ss -tulnape
						;;

					# 修改虚拟内存大小
					12)
						root_use

						# 获取当前交换空间信息
						swap_used=$(free -m | awk 'NR==3{print $3}')
						swap_total=$(free -m | awk 'NR==3{print $2}')

            if [ "$swap_total" -eq 0 ]; then
              swap_percentage=0
            else
              swap_percentage=$((swap_used * 100 / swap_total))
            fi

            swap_info="${swap_used}MB/${swap_total}MB (${swap_percentage}%)"

            echo "当前虚拟内存: $swap_info"

            read -p "是否调整大小?(Y/N): " choice

            case "$choice" in
							[Yy])
								# 输入新的虚拟内存大小
								read -p "请输入虚拟内存大小MB: " new_swap
								add_swap

								;;
							[Nn])
								echo "已取消"
								;;
							*)
								echo "无效的选择，请输入 Y 或 N。"
								;;
						esac

						;;

					# 用户管理
					13)
						while true; do
							root_use

							# 显示所有用户、用户权限、用户组、是否在 sudoers 中
							echo -e "${SKYBLUE}用户列表${PLAIN}"
							echo "----------------------------------------------------------------------------"
							printf "%-24s %-34s %-20s %-10s\n" "用户名" "用户权限" "用户组" "sudo 权限"
							while IFS=: read -r username _ userid groupid _ _ homedir shell; do
								groups=$(groups "$username" | cut -d : -f 2)
								sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
								printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
								done < /etc/passwd

							echo ""
							echo -e "${SKYBLUE}账户操作${PLAIN}"
							echo "------------------------"
							echo "1. 创建普通账户             2. 创建高级账户"
							echo "------------------------"
							echo "3. 赋予最高权限             4. 取消最高权限"
							echo "------------------------"
							echo "5. 删除账号"
							echo "------------------------"
							echo "0. 返回上一级选单"
							echo "------------------------"
							read -p "请输入你的选择: " sub_choice

						 case $sub_choice in
						 	# 创建普通账户
							1)
								# 提示用户输入新用户名
								read -p "请输入新用户名: " new_username

								# 创建新用户并设置密码
								useradd -m -s /bin/bash "$new_username"
								passwd "$new_username"

								echo -e "${GREEN}操作已完成。${PLAIN}"
								;;

							# 创建高级账户
							2)
								# 提示用户输入新的用户名
								read -p "请输入新用户名: " new_username

								# 创建新用户并设置密码
								useradd -m -s /bin/bash "$new_username"
								passwd "$new_username"

								# 赋予新用户 sudo 权限
								echo "$new_username ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers

								echo -e "${GREEN}操作已完成。${PLAIN}"
								;;

							# 赋予最高权限
							3)
								read -p "请输入用户名: " username
								# 赋予新用户 sudo 权限
								echo "$username ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers
								;;

							# 取消最高权限
							4)
								read -p "请输入用户名: " username
								# 从 sudoers 文件中移除用户的 sudo 权限
								sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers
								;;

							# 删除账号
							5)
								read -p "请输入要删除的用户名: " username
							 	# 删除用户及其主目录
							 	userdel -r "$username"
								;;

							0)
								break  # 跳出循环，退出菜单
								;;

							*)
								break  # 跳出循环，退出菜单
								;;

						 esac

						done
						;;

					# 用户/密码生成器
					14)
						clear

						echo -e "${SKYBLUE}随机用户名${PLAIN}"
						echo "------------------------"
						for i in {1..5}; do
								username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
								echo "随机用户名 $i: $username"
						done

						echo ""
						echo -e "${SKYBLUE}随机姓名${PLAIN}"
						echo "------------------------"
						first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
						last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

						# 生成5个随机用户姓名
						for i in {1..5}; do
							first_name_index=$((RANDOM % ${#first_names[@]}))
							last_name_index=$((RANDOM % ${#last_names[@]}))
							user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
							echo "随机用户姓名 $i: $user_name"
						done

						echo ""
						echo -e "${SKYBLUE}随机 UUID${PLAIN}"
						echo "------------------------"
						for i in {1..5}; do
							uuid=$(cat /proc/sys/kernel/random/uuid)
							echo "随机UUID $i: $uuid"
						done

            echo ""
            echo -e "${SKYBLUE}16位随机密码${PLAIN}"
            echo "------------------------"
            for i in {1..5}; do
                password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
                echo "随机密码 $i: $password"
            done

            echo ""
            echo -e "${SKYBLUE}32位随机密码${PLAIN}"
            echo "------------------------"
            for i in {1..5}; do
                password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
                echo "随机密码 $i: $password"
            done
            echo ""

						;;

					# 系统时区调整
					15)
						root_use

						while true; do
							echo -e "${SKYBLUE}系统时间信息${PLAIN}"

							# 获取当前系统时区
							timezone=$(current_timezone)

							# 获取当前系统时间
							current_time=$(date +"%Y-%m-%d %H:%M:%S")

							# 显示时区和时间
							echo "当前系统时区：$timezone"
							echo "当前系统时间：$current_time"

							echo ""
							echo "时区切换"
							echo "亚洲------------------------"
							echo "1. 中国上海时间              2. 中国香港时间"
							echo "3. 日本东京时间              4. 韩国首尔时间"
							echo "5. 新加坡时间                6. 印度加尔各答时间"
							echo "7. 阿联酋迪拜时间            8. 澳大利亚悉尼时间"
							echo "欧洲------------------------"
							echo "11. 英国伦敦时间             12. 法国巴黎时间"
							echo "13. 德国柏林时间             14. 俄罗斯莫斯科时间"
							echo "15. 荷兰尤特赖赫特时间       16. 西班牙马德里时间"
							echo "美洲------------------------"
							echo "21. 美国西部时间             22. 美国东部时间"
							echo "23. 加拿大时间               24. 墨西哥时间"
							echo "25. 巴西时间                 26. 阿根廷时间"
							echo "------------------------"
							echo "0. 返回上一级选单"
							echo "------------------------"
							read -p "请输入你的选择: " sub_choice

							case $sub_choice in
								1) set_timedate Asia/Shanghai ;;
								2) set_timedate Asia/Hong_Kong ;;
								3) set_timedate Asia/Tokyo ;;
								4) set_timedate Asia/Seoul ;;
								5) set_timedate Asia/Singapore ;;
								6) set_timedate Asia/Kolkata ;;
								7) set_timedate Asia/Dubai ;;
								8) set_timedate Australia/Sydney ;;
								11) set_timedate Europe/London ;;
								12) set_timedate Europe/Paris ;;
								13) set_timedate Europe/Berlin ;;
								14) set_timedate Europe/Moscow ;;
								15) set_timedate Europe/Amsterdam ;;
								16) set_timedate Europe/Madrid ;;
								21) set_timedate America/Los_Angeles ;;
								22) set_timedate America/New_York ;;
								23) set_timedate America/Vancouver ;;
								24) set_timedate America/Mexico_City ;;
								25) set_timedate America/Sao_Paulo ;;
								26) set_timedate America/Argentina/Buenos_Aires ;;
								0) break ;; # 跳出循环，退出菜单
								*) break ;; # 跳出循环，退出菜单
							esac

						done
						;;

					# 设置 BBR3 加速
					16)
						;;

					# 防火墙高级管理器
					17)
						;;

					# 修改主机名
					18)
						;;

					# 切换系统更新源
					19)
						;;

					# 定时任务管理
					20)
						;;

					# 本机 host 解析
					21)
						;;

					# fail2banSSH 防御程序
					22)
						;;

					# 限流自动关机
					23)
						root_use

						echo -e "${SKYBLUE}当月流量使用情况，重启服务器流量计算会清零！"
						output_status
						echo "$output"

						# 检查是否存在 Limiting_Shut_down.sh 文件
						if [ -f ~/Limiting_Shut_down.sh ]; then
							# 获取 threshold_gb 的值
							threshold_gb=$(grep -oP 'threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
							threshold_tb=$((threshold_gb / 1024))
							echo -e "当前设置的限流阈值为 ${YELLOW}${threshold_gb}${PLAIN} GB / ${YELLOW}${threshold_tb}${PLAIN} TB"
            else
							echo -e "${GREY}当前未启用限流关机功能${PLAIN}"
            fi

            echo ""
						echo "------------------------------------------------"
						echo "系统每分钟会检测实际流量是否到达阈值，到达后会自动关闭服务器！每月1日重置流量重启服务器。"
						read -p "1. 开启限流关机功能    2. 停用限流关机功能    0. 退出  : " Limiting

						case "$Limiting" in
							1)
								# 输入新的虚拟内存大小
								echo "如果实际服务器就 100G 流量，可设置阈值为 95G，提前关机，以免出现流量误差或溢出"
								read -p "请输入流量阈值（单位为：GB）：" threshold_gb
								cd ~
								curl -Ss -O https://raw.githubusercontent.com/oliver556/sh/main/Limiting_Shut_down.sh
								chmod +x ~/Limiting_Shut_down.sh
								sed -i "s/110/$threshold_gb/g" ~/Limiting_Shut_down.sh
								crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
								(crontab -l ; echo "* * * * * ~/Limiting_Shut_down.sh") | crontab - > /dev/null 2>&1
								crontab -l | grep -v 'reboot' | crontab -
								(crontab -l ; echo "0 1 1 * * reboot") | crontab - > /dev/null 2>&1
								echo "限流关机已设置"
								;;

							2)
								crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
								crontab -l | grep -v 'reboot' | crontab -
								rm ~/Limiting_Shut_down.sh
								echo "已关闭限流关机功能"
								;;

							*)
								echo "无效的输入!"
								;;
						esac
						;;

					# ROOT 私钥登录模式
					24)
						;;

					# 重启服务
					99)
						clear
						restart_the_server
						;;

					0)
						leon
						;;

					*)
						echo "无效的输入!"
						;;
				esac
					break_end
			done
			;;

		# 脚本更新
		00)
			cd ~
			clear
			echo -e "${SKYBLUE}更新日志${PLAIN}"
			echo "------------------------"
			echo "全部日志：https://raw.githubusercontent.com/oliver556/sh/main/leon_sh_log.txt"
			echo "------------------------"
			curl -s https://raw.githubusercontent.com/oliver556/sh/main/leon_sh_log.txt | tail -n 35
			echo ""
			echo ""
			sh_v_new=$(curl -s https://raw.githubusercontent.com/oliver556/sh/main/leon.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

			if [ "$sh_v" = "$sh_v_new" ]; then
				echo -e "${GREEN}你已经是最新版本！${YELLOW}v$sh_v${PLAIN}"
			else
				echo "发现新版本！"
				echo -e "当前版本 v$sh_v        最新版本 ${YELLOW}v$sh_v_new${PLAIN}"
				echo "------------------------"
				read -p "确定更新脚本吗？(Y/N): " choice
				case "$choice" in
					[Yy])
						clear
						curl -sS -O https://raw.githubusercontent.com/oliver556/sh/main/leon.sh && chmod +x leon.sh
						echo -e "${GREEN}脚本已更新到最新版本！${YELLOW}v$sh_v_new${PLAIN}"
						break_end
						kejilion
						;;
					[Nn])
						echo "已取消"
						;;
					*)
						;;
				esac
			fi
			;;

		# ------------------------

		# 退出脚本
		0)
				clear
				exit
				;;

		*)
				echo "无效的输入!"
				;;
	esac
		break_end
	done
