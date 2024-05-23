#!/bin/bash

# 脚本版本
sh_v="1.0.21"

# 颜色 --------------------------------------------------------------------------------------------------------
# 文本颜色 -----------------------------------------------------------------------------------------------------
# 黑色										 # 红色						 	   # 绿色                 	# 黄色								    # 蓝色 (青色)
black=$(tput setaf 0)  ; red=$(tput setaf 1) ; green=$(tput setaf 2); yellow=$(tput setaf 3); blue=$(tput setaf 4);
# 品红色									 # 青色 (天蓝色)			   # 白色									# 灰色
magenta=$(tput setaf 5); cyan=$(tput setaf 6); white=$(tput setaf 7); grey=$(tput setaf 8);
# 重置正常文本属性					 # 加粗字体
normal=$(tput sgr0)	   ; bold=$(tput bold)   ;


# -----------------------------------------------背景颜色------------------------------------------------------
# 黑色背景									# 红色背景											 # 绿色背景								 # 黄色背景
on_black=$(tput setab 0); on_red=$(tput setab 1)       ; on_green=$(tput setab 2); on_yellow=$(tput setab 3)
# 蓝色背景									# 品红色背景										 # 青色背景							 	 # 白色背景
on_blue=$(tput setab 4) ; on_magenta=$(tput setab 5)   ; on_cyan=$(tput setab 6) ; on_white=$(tput setab 7)

# ---------------------------------------------特定的文本属性---------------------------------------------------
# 闪烁（不是所有终端都支持）	  # 隐藏光标										 	# 恢复光标							 	# 加粗
shanshuo=$(tput blink)    ; wuguangbiao=$(tput civis)   ; guangbiao=$(tput cnorm); jiacu=${normal}${bold}
# 下划线开始								  # 重置下划线									  # 变暗
underline=$(tput smul)    ; reset_underline=$(tput rmul); dim=$(tput dim)
# 突出显示（翻转前景色和背景色） # 重置突出显示									# 使用突出显示来作为标题
standout=$(tput smso)     ; reset_standout=$(tput rmso) ; title=${standout}

# ----------------------------------------------字体加背景色----------------------------------------------------
# 白黄色													 # 白蓝色											 # 白绿色
baihuangse=${white}${on_yellow}; bailanse=${white}${on_blue} ; bailvse=${white}${on_green}

# 白青色													 # 白红色											 # 白紫色
baiqingse=${white}${on_cyan}   ; baihongse=${white}${on_red} ; baizise=${white}${on_magenta}

# 黑白色													 # 黑黄色
heibaise=${black}${on_white}   ; heihuangse=${on_yellow}${black}

# -----------------------------------------------提示字样------------------------------------------------------
# 表示 "ERROR" 的提示											 # 表示"ATTENTION"的提示												# 表示"WARNING"的提示
CW="${bold}${baihongse} ERROR ${jiacu}"; ZY="${baihongse}${bold} ATTENTION ${jiacu}"; JG="${baihongse}${bold} WARNING ${jiacu}"


# 复制将当前目录下的 leon.sh 文件复制到 /usr/local/bin 目录，并将其重命名为 n。
# 复制过程中所有的输出信息和错误信息都被重定向到 /dev/null，因此不会在终端显示任何输出。这通常用于静默执行命令，避免输出干扰。
cp ./leon.sh /usr/local/bin/n > /dev/null 2>&1


# ToDo 以下属于通用函数

# 函数: 提示用户按任意键继续

break_end() {
	echo -e "${green}操作完成${normal}"
	echo "按任意键继续..."
	read -n 1 -s -r -p ""
	echo ""
	clear
}

# 函数: 重头执行函数
leon() {
	n
	exit
}

# 函数: 是否以 root 用户身份运行
root_use() {
	clear
	[ "$EUID" -ne 0 ] && echo -e "${red}请注意，该功能需要 root 用户 才能运行！${normal}" && break_end && leon
}

# 函数: 判断服务器系统类型
detect_system() {
	if [ -f /etc/os-release ]; then
		. /etc/os-release
		if [ "$ID" = "debian" ] || [ "$ID" = "ubuntu" ]; then
			echo "This is a Debian or Ubuntu based system"
			echo "这是基于 Debian 或 Ubuntu 的系统"
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

# 函数: 安装软件包
install() {
	if [ $# -eq 0 ]; then
		echo "未提供软件包参数!"
		return 1
	fi

	for package in "$@"; do
		if ! command -v "$package" &>/dev/null; then
			if command -v dnf &>/dev/null; then
				dnf -y update && dnf install -y "$package"
			elif command -v yum &>/dev/null; then
				yum -y update && yum -y install "$package"
			elif command -v apt &>/dev/null; then
				apt update -y && apt install -y "$package"
			elif command -v apk &>/dev/null; then
				apk update && apk add "$package"
			else
				echo "未知的包管理器!"
				return 1
			fi
		fi
	done

	return 0
}

# 函数: 卸载软件包
remove() {
	if [ $# -eq 0 ]; then
		echo "未提供软件包参数!"
		return 1
	fi

	for package in "$@"; do
		if command -v dnf &>/dev/null; then
			dnf remove -y "${package}*"
		elif command -v yum &>/dev/null; then
			yum remove -y "${package}*"
		elif command -v apt &>/dev/null; then
			apt purge -y "${package}*"
		elif command -v apk &>/dev/null; then
			apk del "${package}*"
		else
			echo "未知的包管理器!"
			return 1
		fi
	done

	return 0
}

# ToDo ====================================================================================================
# ToDo 以下属于个人新增函数
# ToDo ====================================================================================================
# ToDo ====================================================================================================
# ToDo ====================================================================================================
# ToDo ====================================================================================================
# ToDo ====================================================================================================
# ToDo ====================================================================================================
# ToDo ====================================================================================================

# 函数: speedtest 测速工具
speed_test_tool() {
	# 判断系统类型
	detect_system

	# Debian、Ubuntu
	if [ "$ID" = "debian" ] || [ "$ID" = "ubuntu" ]; then
		# 检查 curl 是否已安装
		if ! command -v curl &> /dev/null; then
			echo "curl 未安装，开始安装..."
			install curl

		else
			# 更新一下
			install curl
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
			install speedtest
			echo ""
			clear
			echo "------------------------"
			echo "安装已完成"
			echo "正在运行 Speedtest"
			speedtest
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
	# ToDo 需要在 centos 上验证
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
			echo "正在运行 Speedtest"
			speedtest
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

# 函数: 函数用于检查命令是否已安装，未安装的进行安装
check_command() {
	local command_name="$1"  # 将输入的命令名保存到变量

	if ! command -v "$command_name" &>/dev/null; then
		echo "$command_name 未安装，正在进行安装..."
		install "$command_name"  # 使用引号包围变量以正确传递参数
	fi
}

# ToDo ====================================================================================================
# ToDo 以下属于 kejilion 函数
# ToDo ====================================================================================================
# ToDo ====================================================================================================
# ToDo ====================================================================================================
# ToDo ====================================================================================================
# ToDo ====================================================================================================
# ToDo ====================================================================================================
# ToDo ====================================================================================================

# 获取服务器 IPV4、IPV6 公网地址
ip_address() {
	ipv4_address=$(curl -s ipv4.ip.sb)
	ipv6_address=$(curl -s --max-time 1 ipv6.ip.sb)
}

# 函数: 获取服务器流量统计状态，格式化输出（单位保留 GB）
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

			printf("总接收:\t\t%.2f %s\n总发送:\t\t%.2f %s\n", rx_total, rx_units, tx_total, tx_units);
		}' /proc/net/dev)
}

# 函数: 系统更新
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

# 函数: 清理不同 Linux 发行版（Debian、Red Hat、Alpine）系统的函数。它根据系统版本使用不同的清理命令，
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
		# 清理系统日志，保留不超过 50MB 的日志
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
		# 清理老旧的系统日志，保留不超过 1 秒的日志
		journalctl --vacuum-time=1s
		# 清理系统日志，保留不超过 50MB 的日志
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

# 函数: 启用 BBR 拥塞控制算法
bbr_on() {
	# 将以下内容覆盖写入 /etc/sysctl.conf 文件中
	cat > /etc/sysctl.conf << EOF
net.core.default_qdisc=fq_pie
net.ipv4.tcp_congestion_control=bbr
EOF
	# 重新加载
	sysctl -p
}

# 函数: 安装更新 Docker 环境
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
		curl -fsSL https://get.docker.com | sh
		systemctl start docker
		systemctl enable docker
	fi

	sleep 2
}

# 函数: 设置允许 ROOT 用户通过 SSH 登录，并设置 ROOT 用户的密码
add_sshpasswd() {
	echo -e "${yellow}设置允许 ROOT 用户通过 SSH 登录，并设置 ROOT 用户的密码${normal}"
	echo "设置你的 ROOT 密码"
	# 提示用户输入两次密码，用于设置 ROOT 用户的密码
	passwd
	# 修改 /etc/ssh/sshd_config 文件来允许 ROOT 用户通过 SSH 登录
	sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
	# 修改 /etc/ssh/sshd_config 文件来允许密码进行认证
	sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
	# 清理 SSH 配置目录下的临时文件
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	# 函数: 根据系统中安装的包管理器来使用适当的命令来重启 SSH 服务
	restart_ssh
	# 显示消息，表示 ROOT 登录设置完成
	echo -e "${green}ROOT 登录设置完毕！${normal}"
	server_reboot
}

# 函数: 根据系统中安装的包管理器来使用适当的命令来重启 SSH 服务
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
		echo -e "${red}无法找到 SSH 服务启动脚本，无法重启 SSH 服务!${normal}"
		return 1
	fi
}

# 函数: 询问用户是否要重启服务器
server_reboot() {
	read -p "$(echo -e "${yellow}现在重启服务器吗？(Y/N): ${normal}")" rboot
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

# 函数: 开放所有端口
iptables_open() {
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

# 函数: 修改 SSH 连接端口
new_ssh_port() {
	# 备份 SSH 配置文件
	cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

	# 使用 sed 替换命令将原先注释掉的端口配置取消注释，即将 #Port 改为 Port
	sed -i 's/^\s*#\?\s*Port/Port/' /etc/ssh/sshd_config

	# 替换 SSH 配置文件中的端口号
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

    # 创建新的 swap 分区
    dd if=/dev/zero of=/swapfile bs=1M count=$new_swap
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    if [ -f /etc/alpine-release ]; then
        echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
        echo "nohup swapon /swapfile" >> /etc/local.d/swap.start
        chmod +x /etc/local.d/swap.start
        rc-update add local
    else
        echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
    fi

    echo -e "虚拟内存大小已调整为${yellow}${new_swap}${normal} MB"
}

# 函数: 获取当前系统时区
current_timezone() {
	if grep -q 'Alpine' /etc/issue; then
		date +"%Z %z"
	else
	 	timedatectl | grep "Time zone" | awk '{print $3}'
	fi
}

# 函数: 根据系统的发行版设置一个变量 xxx 的值，调用 f2b_status_xxx 函数来处理相应的操作
f2b_sshd() {
	if grep -q 'Alpine' /etc/issue; then
		xxx=alpine-sshd
		f2b_status_xxx
	elif grep -qi 'CentOS' /etc/redhat-release; then
		xxx=centos-sshd
		f2b_status_xxx
	else
		xxx=linux-sshd
		f2b_status_xxx
	fi
}

# 函数: 通过 Docker 容器内的 fail2ban-client 工具来获取特定服务的状态信息
f2b_status_xxx() {
	docker exec -it fail2ban fail2ban-client status $xxx
}

# 函数: 检查系统中是否已经安装了 docker 和 docker-compose
install_docker() {
	if ! command -v docker compose &>/dev/null; then
		install_add_docker
	else
		echo -e "${cyan}Docker 环境已安装${normal}"
	fi
}

# 函数: 在 Docker 中运行 fail2ban 容器，并根据系统类型添加适当的配置文件以保护 SSH 服务
f2b_install_sshd() {

	docker run -d \
		--name=fail2ban \
		--net=host \
		--cap-add=NET_ADMIN \
		--cap-add=NET_RAW \
		-e PUID=1000 \
		-e PGID=1000 \
		-e TZ=Etc/UTC \
		-e VERBOSITY=-vv \
		-v /path/to/fail2ban/config:/config \
		-v /var/log:/var/log:ro \
		-v /home/web/log/nginx/:/remotelogs/nginx:ro \
		--restart unless-stopped \
		lscr.io/linuxserver/fail2ban:latest

	sleep 3
	if grep -q 'Alpine' /etc/issue; then
		cd /path/to/fail2ban/config/fail2ban/filter.d
		curl -sS -O https://raw.githubusercontent.com/oliver556/sh/main/config/fail2ban/alpine-sshd.conf
		curl -sS -O https://raw.githubusercontent.com/oliver556/sh/main/config/fail2ban/alpine-sshd-ddos.conf

		cd /path/to/fail2ban/config/fail2ban/jail.d/

		curl -sS -O https://raw.githubusercontent.com/oliver556/sh/main/config/fail2ban/alpine-ssh.conf

	elif grep -qi 'CentOS' /etc/redhat-release; then
		cd /path/to/fail2ban/config/fail2ban/jail.d/
		curl -sS -O https://raw.githubusercontent.com/oliver556/sh/main/config/fail2ban/centos-ssh.conf

	else
		install rsyslog
		systemctl start rsyslog
		systemctl enable rsyslog
		cd /path/to/fail2ban/config/fail2ban/jail.d/
		curl -sS -O https://raw.githubusercontent.com/oliver556/sh/main/config/fail2ban/linux-ssh.conf
	fi
}

# 函数: 重新启动 fail2ban 容器，并使用 fail2ban-client 工具获取 fail2ban 服务的状态信息
f2b_status() {
	 docker restart fail2ban
	 sleep 3
	 docker exec -it fail2ban fail2ban-client status
}

# 函数: 添加密钥
add_sshkey() {

	ssh-keygen -t rsa -b 4096 -C "xxxx@gmail.com" -f /root/.ssh/sshkey -N ""

	cat ~/.ssh/sshkey.pub >> ~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys

	# 获取服务器 IPV4、IPV6 公网地址
	ip_address

	echo -e "私钥信息已生成，务必复制保存，可保存成 ${yellow}${ipv4_address}_ssh.key${normal} 文件，用于以后的 SSH 登录"
	echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
	cat ~/.ssh/sshkey
	echo -e "${cyan}${bold}------------------------------------------------${jiacu}"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
				 -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
				 -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
				 -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

	echo -e "${grey}ROOT 私钥登录已开启，已关闭 ROOT 密码登录，重连将会生效${normal}"
}

# 函数: 检查端口
check_port() {
	# 定义要检测的端口
	PORT=443

	# 检查端口占用情况
	result=$(ss -tulpn | grep ":$PORT")

	# 判断结果并输出相应信息
	if [ -n "$result" ]; then
		is_nginx_container=$(docker ps --format '{{.Names}}' | grep 'nginx')

		# 判断是否是 Nginx 容器占用端口
		if [ -n "$is_nginx_container" ]; then
				echo ""
		else
				clear
				echo -e "${red}端口 ${yellow}$PORT${red} 已被占用，无法安装环境，卸载以下程序后重试！${normal}"
				echo "$result"
				break_end
				leon
		fi

	else
		echo ""
	fi
}

# 函数: 安装依赖 wget socat unzip tar
install_dependency() {
	clear
	install wget socat unzip tar
}

# 函数: 安装 certbot 工具
install_certbot() {
    install certbot

    # 切换到一个一致的目录（例如，家目录）
    cd ~ || exit

    # 下载并使脚本可执行
    curl -O https://raw.githubusercontent.com/oliver556/sh/main/auto_cert_renewal.sh
    chmod +x auto_cert_renewal.sh

    # 设置定时任务字符串
    cron_job="0 0 * * * ~/auto_cert_renewal.sh"

    # 检查是否存在相同的定时任务
    existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

    # 如果不存在，则添加定时任务
    if [ -z "$existing_cron" ]; then
		(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
		echo "续签任务已添加"
    else
		echo "续签任务已存在，无需添加"
    fi
}

# 函数: 创建自签名的 SSL 证书并将其存储在指定的目录中
default_server_ssl() {
	install openssl
	openssl req -x509 -nodes -newkey rsa:2048 -keyout /home/web/certs/default_server.key -out /home/web/certs/default_server.crt -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
}

# 函数: 获取 SSL/TLS 证书
install_ssltls() {
	docker stop nginx > /dev/null 2>&1
	iptables_open
	cd ~
	certbot certonly --standalone -d $yuming --email your@email.com --agree-tos --no-eff-email --force-renewal
	cp /etc/letsencrypt/live/$yuming/fullchain.pem /home/web/certs/${yuming}_cert.pem
	cp /etc/letsencrypt/live/$yuming/privkey.pem /home/web/certs/${yuming}_key.pem
	docker start nginx > /dev/null 2>&1
}

# 函数: Nginx 环境检查
nginx_install_status() {

	if docker inspect "nginx" &>/dev/null; then
		echo "nginx 环境已安装，开始部署 $webname"
	else
		echo -e "${yellow}nginx 未安装，请先安装 nginx 环境，再部署网站${normal}"

	break_end
	leon
 	fi
}

# 函数: 获取 IP，及收集用户输入要解析的域名
add_yuming() {
	ip_address
	echo -e "先将域名解析到本机IP: ${yellow}$ipv4_address  $ipv6_address${normal}"
	read -p "请输入你解析的域名: " yuming
	repeat_add_yuming
}

# 函数: 输出建站 IP
nginx_web_on() {
	clear
	echo "您的 $webname 搭建好了！"
	echo "https://$yuming"
}

# 函数: 检查 docker、证书申请 状态
nginx_status() {

	sleep 1

	nginx_container_name="nginx"

	# 获取容器的状态
	container_status=$(docker inspect -f '{{.State.Status}}' "$nginx_container_name" 2>/dev/null)

	# 获取容器的重启状态
	container_restart_count=$(docker inspect -f '{{.RestartCount}}' "$nginx_container_name" 2>/dev/null)

	# 检查容器是否在运行，并且没有处于"Restarting"状态
	if [ "$container_status" == "running" ]; then
		echo ""
	else
		rm -r /home/web/html/$yuming >/dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf >/dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem >/dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem >/dev/null 2>&1
		docker restart nginx >/dev/null 2>&1

		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE $dbname;" 2> /dev/null

		echo -e "${red}检测到域名证书申请失败，请检测域名是否正确解析或更换域名重新尝试！${normal}"
	fi

}

# 函数: ToDo
install_panel() {
	if $lujing ; then
		clear
		echo -e "${green}$panelname 已安装，应用操作"
		echo ""
		echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
		echo "1. 管理$panelname          2. 卸载$panelname"
		echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
		echo "0. 返回上一级选单"
		echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
		read -p "请输入你的选择: " sub_choice

		case $sub_choice in
			1)
				clear
				$gongneng1
				$gongneng1_1
				;;

			2)
				clear
				$gongneng2
				$gongneng2_1
				$gongneng2_2
				;;

			0)
				break  # 跳出循环，退出菜单
				;;

			*)
				break  # 跳出循环，退出菜单
				;;
		esac

	else
		clear
		echo -e "${yellow}安装提示${normal}"
		echo "如果您已经安装了其他面板工具或者 LDNMP 建站环境，建议先卸载，再安装 $panelname！"
		echo "会根据系统自动安装，支持Debian，Ubuntu，Centos"
		echo "官网介绍: $panelurl "
		echo ""

		read -p "确定安装 $panelname 吗？(Y/N): " choice
		case "$choice" in
			[Yy])
				# 开放所有端口
				iptables_open
				install wget
				if grep -q 'Alpine' /etc/issue; then
					$ubuntu_mingling
					$ubuntu_mingling2
				elif grep -qi 'CentOS' /etc/redhat-release; then
					$centos_mingling
					$centos_mingling2
				elif grep -qi 'Ubuntu' /etc/os-release; then
					$ubuntu_mingling
					$ubuntu_mingling2
				elif grep -qi 'Debian' /etc/os-release; then
					$ubuntu_mingling
					$ubuntu_mingling2
				else
					echo "Unsupported OS"
				fi
				;;

			[Nn])
				;;

			*)
				;;
				esac
	fi
}

# 函数: ToDo
iptables_open() {
	iptables -P INPUT ACCEPT
	iptables -P FORWARD ACCEPT
	iptables -P OUTPUT ACCEPT
	iptables -F

	ip6tables -P INPUT ACCEPT
	ip6tables -P FORWARD ACCEPT
	ip6tables -P OUTPUT ACCEPT
	ip6tables -F
}

# 函数: 设置时区
set_timedate() {
	shiqu="$1"
	if grep -q 'Alpine' /etc/issue; then
		install tzdata
		cp /usr/share/zoneinfo/${shiqu} /etc/localtime
		hwclock --systohc
	else
		timedatectl set-timezone ${shiqu}
	fi
}

# 函数: 获取当前环境中 Nginx、MySQL、PHP 和 Redis 的版本信息
ldnmp_v() {
      # 获取 nginx 版本
      nginx_version=$(docker exec nginx nginx -v 2>&1)
      nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
      echo -n -e "nginx : ${huang}v$nginx_version${bai}"

      # 获取 mysql 版本
      dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
      echo -n -e "            mysql : ${huang}v$mysql_version${bai}"

      # 获取 php 版本
      php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
      echo -n -e "            php : ${huang}v$php_version${bai}"

      # 获取 redis 版本
      redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
      echo -e "            redis : ${huang}v$redis_version${bai}"

      echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
      echo ""
}

# 函数: 更新 LDNMP 环境
install_ldnmp() {

	new_swap=1024
	add_swap

	cd /home/web && docker compose up -d
	clear
	echo -e "${cyan}正在配置 LDNMP 环境，请耐心稍等……${normal}"

	# 定义要执行的命令
	commands=(
		"docker exec nginx chmod -R 777 /var/www/html"
		"docker restart nginx > /dev/null 2>&1"

		"docker exec php apk update > /dev/null 2>&1"
		"docker exec php74 apk update > /dev/null 2>&1"

		# php 安装包管理
		"curl -sL https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions > /dev/null 2>&1"
		"docker exec php mkdir -p /usr/local/bin/ > /dev/null 2>&1"
		"docker exec php74 mkdir -p /usr/local/bin/ > /dev/null 2>&1"
		"docker cp /usr/local/bin/install-php-extensions php:/usr/local/bin/ > /dev/null 2>&1"
		"docker cp /usr/local/bin/install-php-extensions php74:/usr/local/bin/ > /dev/null 2>&1"
		"docker exec php chmod +x /usr/local/bin/install-php-extensions > /dev/null 2>&1"
		"docker exec php74 chmod +x /usr/local/bin/install-php-extensions > /dev/null 2>&1"

		# php 安装扩展
		"docker exec php install-php-extensions mysqli > /dev/null 2>&1"
		"docker exec php install-php-extensions pdo_mysql > /dev/null 2>&1"
		"docker exec php install-php-extensions gd > /dev/null 2>&1"
		"docker exec php install-php-extensions intl > /dev/null 2>&1"
		"docker exec php install-php-extensions zip > /dev/null 2>&1"
		"docker exec php install-php-extensions exif > /dev/null 2>&1"
		"docker exec php install-php-extensions bcmath > /dev/null 2>&1"
		"docker exec php install-php-extensions opcache > /dev/null 2>&1"
		"docker exec php install-php-extensions imagick > /dev/null 2>&1"
		"docker exec php install-php-extensions redis > /dev/null 2>&1"

		# php 配置参数
		"docker exec php sh -c 'echo \"upload_max_filesize=50M \" > /usr/local/etc/php/conf.d/uploads.ini' > /dev/null 2>&1"
		"docker exec php sh -c 'echo \"post_max_size=50M \" > /usr/local/etc/php/conf.d/post.ini' > /dev/null 2>&1"
		"docker exec php sh -c 'echo \"memory_limit=256M\" > /usr/local/etc/php/conf.d/memory.ini' > /dev/null 2>&1"
		"docker exec php sh -c 'echo \"max_execution_time=1200\" > /usr/local/etc/php/conf.d/max_execution_time.ini' > /dev/null 2>&1"
		"docker exec php sh -c 'echo \"max_input_time=600\" > /usr/local/etc/php/conf.d/max_input_time.ini' > /dev/null 2>&1"

		# php 重启
		"docker exec php chmod -R 777 /var/www/html"
		"docker restart php > /dev/null 2>&1"

		# php7.4 安装扩展
		"docker exec php74 install-php-extensions mysqli > /dev/null 2>&1"
		"docker exec php74 install-php-extensions pdo_mysql > /dev/null 2>&1"
		"docker exec php74 install-php-extensions gd > /dev/null 2>&1"
		"docker exec php74 install-php-extensions intl > /dev/null 2>&1"
		"docker exec php74 install-php-extensions zip > /dev/null 2>&1"
		"docker exec php74 install-php-extensions exif > /dev/null 2>&1"
		"docker exec php74 install-php-extensions bcmath > /dev/null 2>&1"
		"docker exec php74 install-php-extensions opcache > /dev/null 2>&1"
		"docker exec php74 install-php-extensions imagick > /dev/null 2>&1"
		"docker exec php74 install-php-extensions redis > /dev/null 2>&1"

		# php7.4 配置参数
		"docker exec php74 sh -c 'echo \"upload_max_filesize=50M \" > /usr/local/etc/php/conf.d/uploads.ini' > /dev/null 2>&1"
		"docker exec php74 sh -c 'echo \"post_max_size=50M \" > /usr/local/etc/php/conf.d/post.ini' > /dev/null 2>&1"
		"docker exec php74 sh -c 'echo \"memory_limit=256M\" > /usr/local/etc/php/conf.d/memory.ini' > /dev/null 2>&1"
		"docker exec php74 sh -c 'echo \"max_execution_time=1200\" > /usr/local/etc/php/conf.d/max_execution_time.ini' > /dev/null 2>&1"
		"docker exec php74 sh -c 'echo \"max_input_time=600\" > /usr/local/etc/php/conf.d/max_input_time.ini' > /dev/null 2>&1"

		# php7.4 重启
		"docker exec php74 chmod -R 777 /var/www/html"
		"docker restart php74 > /dev/null 2>&1"
	)
	# 计算总命令数
	total_commands=${#commands[@]}

	for ((i = 0; i < total_commands; i++)); do
		command="${commands[i]}"
		eval $command  # 执行命令

		# 打印百分比和进度条
		percentage=$(( (i + 1) * 100 / total_commands ))
		completed=$(( percentage / 2 ))
		remaining=$(( 50 - completed ))
		progressBar="["
		for ((j = 0; j < completed; j++)); do
		  	progressBar+="#"
		done
		for ((j = 0; j < remaining; j++)); do
		  	progressBar+="."
		done
			progressBar+="]"
			echo -ne "\r[${lv}$percentage%${bai}] $progressBar"
		done

	  	echo  # 打印换行，以便输出不被覆盖


	  	clear
		echo -e "${green}LDNMP 环境安装完毕${normal}"
		echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
		# 获取当前环境中 Nginx、MySQL、PHP 和 Redis 的版本信息
	  	ldnmp_v
}

# 函数: 检查是否安装 LDNMP 环境
ldnmp_install_status() {
   if docker inspect "php" &>/dev/null; then
    	echo "LDNMP 环境已安装，开始部署 $webname"
   else

	echo -e "${yellow}LDNMP 环境未安装，请先安装 LDNMP 环境，再部署网站${normal}"
    break_end
    leon
   fi
}

# 函数: 解析指定的 docker-compose.yml 文件中的 MySQL 配置
# 创建一个新的数据库，并设置权限以允许给定用户对该数据库进行全部权限
add_db() {
	dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
	dbname="${dbname}"

	dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	docker exec mysql mysql -u root -p"$dbrootpasswd" -e "CREATE DATABASE $dbname; GRANT ALL PRIVILEGES ON $dbname.* TO \"$dbuse\"@\"%\";"
}

# 函数: 设置 nginx、php 目录权限并重启
restart_ldnmp() {
	docker exec nginx chmod -R 777 /var/www/html
	docker exec php chmod -R 777 /var/www/html
	docker exec php74 chmod -R 777 /var/www/html

	docker restart nginx
	docker restart php
	docker restart php74
}

# 函数: 获取域名地址，进行提示
ldnmp_web_on() {
	clear
	echo -e "${green}您的 $webname 搭建好了！${normal}"
	echo "https://$yuming"
	echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
	echo "$webname 安装信息如下: "

}

repeat_add_yuming() {
	if [ -e /home/web/conf.d/$yuming.conf ]; then
    echo -e "${yellow}当前 ${yuming} 域名已被使用，请前往31站点管理，删除站点，再部署 ${webname} ！${normal}"
    break_end
    leon
	else
    echo "当前 ${yuming} 域名可用"
	fi
}

docker_app() {
	if docker inspect "$docker_name" &>/dev/null; then
		clear
		echo -e "${green}$docker_name 已安装，访问地址: ${normal}"
		ip_address
		echo "http:$ipv4_address:$docker_port"
		echo ""
		echo -e "${cyan}应用操作${normal}"
		echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
		echo "1. 更新应用             2. 卸载应用"
		echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
		echo "0. 返回上一级选单"
		echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
		read -p "请输入你的选择: " sub_choice

		case $sub_choice in
			1)
				clear
				docker rm -f "$docker_name"
				docker rmi -f "$docker_img"

				$docker_rum
				clear
				echo -e "${green}$docker_name 已经安装完成${normal}"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				# 获取外部 IP 地址
				ip_address
				echo "您可以使用以下地址访问:"
				echo "http:$ipv4_address:$docker_port"
				$docker_use
				$docker_passwd
				;;

			2)
				clear
				docker rm -f "$docker_name"
				docker rmi -f "$docker_img"
				rm -rf "/home/docker/$docker_name"
				echo -e "${green}应用已卸载${normal}"
				;;

			0)
				# 跳出循环，退出菜单
				;;

			*)
				# 跳出循环，退出菜单
				;;
			esac

	else
		clear
		echo "安装提示"
		echo "$docker_describe"
		echo "$docker_url"
		echo ""

		# 提示用户确认安装
		read -p "确定安装吗？(Y/N): " choice

		case "$choice" in
			[Yy])
				clear
				# 安装 Docker（请确保有 install_docker 函数）
				install_docker
				$docker_rum
				clear
				echo "$docker_name 已经安装完成"
				echo "------------------------"
				# 获取外部 IP 地址
				ip_address
				echo "您可以使用以下地址访问:"
				echo "http:$ipv4_address:$docker_port"
				$docker_use
				$docker_passwd
				;;

			[Nn])
				# 用户选择不安装
				;;

			*)
				# 无效输入
				;;
		esac
	fi

}

cluster_python3() {
	cd ~/cluster/
	# To大Do
	curl -sS -O https://raw.githubusercontent.com/kejilion/python-for-vps/main/cluster/$py_task
	python3 ~/cluster/$py_task
}

tmux_run() {
	# 检查会话是否已经存在
	tmux has-session -t $SESSION_NAME 2>/dev/null
	# $? 是一个特殊变量，可保持最后执行命令的退出状态
	if [ $? != 0 ]; then
		# 会话不存在，创建一个新的会话
		tmux new -s $SESSION_NAME
	else
		# 会话存在，附加
		tmux attach-session -t $SESSION_NAME
	fi
}

set_dns() {

	# 检查机器是否有 IPv6 地址
	ipv6_available=0
	if [[ $(ip -6 addr | grep -c "inet6") -gt 0 ]]; then
    ipv6_available=1
	fi

	echo "nameserver $dns1_ipv4" > /etc/resolv.conf
	echo "nameserver $dns2_ipv4" >> /etc/resolv.conf


	if [[ $ipv6_available -eq 1 ]]; then
    echo "nameserver $dns1_ipv6" >> /etc/resolv.conf
    echo "nameserver $dns2_ipv6" >> /etc/resolv.conf
	fi

	echo "DNS地址已更新"
	echo "------------------------"
	cat /etc/resolv.conf
	echo "------------------------"
}

# ToDo 还未使用
# 函数: 设置反向代理配置，修改 Nginx 反向代理配置文件
reverse_proxy() {
	# 获取服务器 IPV4、IPV6 公网地址
	ip_address

	wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/oliver556/sh/main/nginx/reverse-proxy.conf
	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	sed -i "s/0.0.0.0/$ipv4_address/g" /home/web/conf.d/$yuming.conf
	sed -i "s/0000/$duankou/g" /home/web/conf.d/$yuming.conf

	# 重启 Nginx 服务器
	docker restart nginx
}

# ToDo ====================================================================================================
# ToDo ====================================================================================================
# ToDo ====================================================================================================
# ToDo ====================================================================================================
# ToDo ====================================================================================================
# ToDo ====================================================================================================
# ToDo ====================================================================================================
# ToDo ====================================================================================================

while true; do
	clear

	echo -e "${green}${bold}# ==========================================================="
	echo -e "${green}# _    ____ ____ _  _ "
	echo -e "${green}# |    |___ |  | |\ | "
	echo -e "${green}# |___ |___ |__| | \|   ${cyan}v$sh_v${normal}"
	echo -e "${green}${bold}# "
	echo -e "${green}# Leon 一键脚本工具（支持 Ubuntu/Debian/CentOS/Alpine 系统）${normal}"
	echo -e "${green}${bold}# 输入${yellow} n ${green}可快速启动此脚本 ${normal}"
	echo -e "${green}${bold}# ===========================================================${jiacu}"
	echo ""
	echo "1. 系统信息查询"
	echo "2. 系统更新"
	echo "3. 系统清理"
	echo "4. 常用工具 ▶"
	echo "5. BBR 管理 ▶"
	echo "6. Docker 管理 ▶ "
#	echo "7. WARP 管理 ▶ "
	echo "8. 测试脚本合集 ▶ "
	echo "9. 甲骨文云脚本合集 ▶ "
	echo "10. LDNMP 建站 ▶ "
	echo "11. 面板工具 ▶ "
	echo "12. 我的工作区 ▶ "
	echo "13. 系统工具 ▶ "
	echo "14. VPS 集群控制 ▶ "
	echo "------------------------"
	echo "p. 幻兽帕鲁开服脚本 ▶"
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

    		echo -e "${cyan}查询中，请稍后，很快就好......${jiacu}"

			# 获取服务器 IPV4、IPV6 公网地址
			ip_address

			# ------------------------------------------------
			# 获取主机名
			hostname=$(hostname)

			# 获取服务器 IP 地址所属的组织（如 ISP 或公司）(包含了关于 IP 地址的详细信息，包括组织、位置、ASN 等)
			isp_info=$(curl -s ipinfo.io/org)

			# ------------------------------------------------
			# 尝试使用 lsb_release 获取系统信息
			os_info=$(lsb_release -ds 2>/dev/null)

			# 如果 lsb_release 命令失败，则尝试其他方法
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

			# ------------------------------------------------
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

			# ------------------------------------------------
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

			# ------------------------------------------------
			# 获取网络拥堵算法
			congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
			queue_algorithm=$(sysctl -n net.core.default_qdisc)

			# ------------------------------------------------
			# 获取地理位置 / 城市
			country=$(curl -s ipinfo.io/country)
			city=$(curl -s ipinfo.io/city)

			# 获取系统时间
    		current_time=$(date "+%Y-%m-%d %I:%M %p")

			# 系统运行时长
			runtime=$(cat /proc/uptime | awk -F. '{run_days=int($1 / 86400);run_hours=int(($1 % 86400) / 3600);run_minutes=int(($1 % 3600) / 60); if (run_days > 0) printf("%d天 ", run_days); if (run_hours > 0) printf("%d时 ", run_hours); printf("%d分\n", run_minutes)}')

			# 系统时区
			timezone=$(current_timezone)

			# 获取服务器流量统计状态，格式化输出（单位保留 GB）
			output_status

			clear

	    	echo ""
			echo -e "${baizise}${bold}                  系统信息查询                  ${jiacu}"
			echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
			echo "主机名:		$hostname"
			echo "运营商:		$isp_info"
			echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
			echo "系统版本:	$os_info"
			echo "Linux 版本:	$kernel_version"
			echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
			echo "CPU 架构:	$cpu_arch"
			echo "CPU 型号:	$cpu_info"
			echo "CPU 核心数:	$cpu_cores"
			echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
			echo "CPU 占用:	$cpu_usage_percent%"
			echo "物理内存:	$mem_info"
			echo "虚拟内存:	$swap_info"
			echo "硬盘占用:	$disk_info"
			echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
			echo "$output"
			echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
			echo "网络拥堵算法:	$congestion_algorithm $queue_algorithm"
			echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
			echo "公网 IPv4 地址:	$ipv4_address"
			echo "公网 IPv6 地址:	$ipv6_address"
			echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
			echo "地理位置:	$country $city"
			echo "系统时间:	$current_time"
			echo "系统时间:	$current_time"
			echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
			echo "系统运行时长: $runtime"
			echo -e "${cyan}${bold}------------------------------------------------${jiacu}"

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

		# 常用工具 ▶
  		4)
			while true; do
				clear
				echo -e "${baizise}${bold}                  ▶ 安装常用工具                ${jiacu}"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
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
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "21. cmatrix 黑客帝国屏保"
#				echo "22. sl 跑火车屏保"
#				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
#				echo "26. 俄罗斯方块小游戏"
#				echo "27. 贪吃蛇小游戏"
#				echo "28. 太空入侵者小游戏"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "31. 全部安装"
				echo "32. 全部卸载"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "41. 安装指定工具"
				echo "42. 卸载指定工具"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "0. 返回主菜单"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				read -p "请输入你的选择: " sub_choice

				case $sub_choice in
					# curl 下载工具
					1)
						clear
						install curl
						clear
						echo -e "${baizise}工具已安装，使用方法如下: ${jiacu}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						curl --help
						;;

					# wget 下载工具
					2)
						clear
						install wget
						clear
						echo -e "${baizise}工具已安装，使用方法如下: ${jiacu}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						wget --help
						;;

					# sudo 超级管理权限工具
					3)
						clear
						install sudo
						clear
						echo -e "${baizise}工具已安装，使用方法如下: ${jiacu}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						sudo --help
						;;

					# socat 通信连接工具 （申请域名证书必备）
					4)
						clear
						install socat
						clear
						echo -e "${baizise}工具已安装，使用方法如下: ${jiacu}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
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

					# unzip ZIP 压缩解压工具
					7)
						clear
						install unzip
						clear
						echo -e "${baizise}工具已安装，使用方法如下: ${jiacu}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						unzip
						;;

					# tar GZ 压缩解压工具
					8)
						clear
						install tar
						clear
						echo -e "${baizise}工具已安装，使用方法如下: ${jiacu}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						tar --help
						;;

					# tmux 多路后台运行工具
					9)
						clear
						install tmux
						clear
						echo -e "${baizise}工具已安装，使用方法如下: ${jiacu}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						tmux --help
						;;

					# ffmpeg 视频编码直播推流工具
					10)
						clear
						install ffmpeg
						clear
						echo -e "${baizise}工具已安装，使用方法如下: ${jiacu}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
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
						sleep 2
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

					# ------------------------------------------------
					# cmatrix 黑客帝国屏保
					21)
						clear
						install cmatrix
						clear
						cmatrix
						;;
					# ------------------------------------------------
#					 sl 跑火车屏保
#					22)
#						clear
#						install sl
#						clear
#						/usr/games/sl
#						;;
#
#					 俄罗斯方块小游戏
#					26)
#						clear
#						install bastet
#						clear
#						/usr/games/bastet
#						;;
#
#					 贪吃蛇小游戏
#					27)
#						clear
#						install nsnake
#						clear
#						/usr/games/nsnake
#						;;
#
#					 太空入侵者小游戏
#					28)
#						clear
#						install ninvaders
#						clear
#						/usr/games/ninvaders
#						;;

					# ------------------------------------------------
					# 全部安装
					31)
						clear
						# btop ranger sl bastet nsnake ninvaders
						install curl wget sudo socat htop iftop unzip tar tmux ffmpeg gdu fzf cmatrix nsnake
						;;

					# 全部卸载
					32)
						clear
						remove htop iftop unzip tmux ffmpeg gdu fzf cmatrix
						;;

					# ------------------------------------------------
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

					# ------------------------------------------------
					# 返回主菜单
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

		# BBR 管理
  		5)
			clear
			if [ -f "/etc/alpine-release" ]; then
				while true; do
					clear
					congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
					queue_algorithm=$(sysctl -n net.core.default_qdisc)
					echo "当前 TCP 阻塞算法: $congestion_algorithm $queue_algorithm"

					echo ""
					echo -e "${baizise}${bold}                  BBR 管理                      ${jiacu}"
					echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
					echo "1. 开启 BBRv3              2. 关闭 BBRv3（会重启）"
					echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
					echo "0. 返回上一级选单"
					echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
					read -p "请输入你的选择: " sub_choice

					case $sub_choice in
						# 开启 BBRv3
						1)
							# 启用 BBR 拥塞控制算法
							bbr_on
							;;

						# 关闭 BBRv3（会重启）
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
				echo -e "${baizise}${bold}                  ▶ Docker 管理器               ${jiacu}"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "1. 安装更新 Docker 环境"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "2. 查看 Docker 全局状态"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "3. Docker 容器管理 ▶"
				echo "4. Docker 镜像管理 ▶"
				echo "5. Docker 网络管理 ▶"
				echo "6. Docker 卷管理 ▶"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "7. 清理无用的 Docker 容器和镜像网络数据卷"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "8. 卸载 Docker 环境"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "0. 返回主菜单"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				read -p "请输入你的选择: " sub_choice

      			case $sub_choice in
      				# 安装更新 Docker 环境
          			1)
						clear
						# 安装更新 Docker 环境
						install_add_docker
						;;

					# 查看 Docker 全局状态
					2)
						clear
						echo -e "${cyan}Docker 版本${normal}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						docker -v
						docker compose version

						echo ""
						echo -e "${cyan}Docker 镜像列表${normal}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						docker image ls
						echo ""
						echo -e "${cyan}Docker 容器列表${normal}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						docker ps -a
						echo ""
						echo -e "${cyan}Docker 卷列表${normal}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						docker volume ls
						echo ""
						echo -e "${cyan}Docker 网络列表${normal}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						docker network ls
						echo ""
						;;

					# Docker 容器管理
          			3)
						while true; do
						clear
              			echo -e "${cyan}Docker 容器列表${normal}"
						docker ps -a
						echo ""
						echo -e "${baizise}${bold}                  容器操作                      ${jiacu}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						echo "1. 创建新的容器"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						echo "2. 启动指定容器             6. 启动所有容器"
						echo "3. 停止指定容器             7. 暂停所有容器"
						echo "4. 删除指定容器             8. 删除所有容器"
						echo "5. 重启指定容器             9. 重启所有容器"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						echo "11. 进入指定容器           12. 查看容器日志           13. 查看容器网络"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						echo "0. 返回上一级选单"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"

						read -p "请输入你的选择: " sub_choice

						case $sub_choice in
							# 创建新的容器
							1)
								read -p "请输入创建命令: " dockername
								$dockername
								;;

							# 启动指定容器
							2)
								read -p "请输入容器名: " dockername
								docker start $dockername
								;;

							# 停止指定容器
							3)
								read -p "请输入容器名: " dockername
								docker stop $dockername
								;;

							# 删除指定容器
							4)
								read -p "请输入容器名: " dockername
								docker rm -f $dockername
								;;

							# 重启指定容器
							5)
								read -p "请输入容器名: " dockername
								docker restart $dockername
								;;

							# 启动所有容器
							6)
								docker start $(docker ps -a -q)
								;;

							# 暂停所有容器
							7)
								docker stop $(docker ps -q)
								;;

							# 删除所有容器
							8)
								read -p "$(echo -e "${red}确定删除所有容器吗？(Y/N): ${normal}")" choice

								case "$choice" in
									[Yy])
										docker rm -f $(docker ps -a -q)
										;;
									[Nn])
										;;
									*)
										echo "无效的选择，请输入 Y 或 N。"
										;;
								esac
								;;

							# 重启所有容器
							9)
								docker restart $(docker ps -q)
								;;

							# 进入指定容器
							11)
								read -p "请输入容器名: " dockername
								docker exec -it $dockername /bin/sh
								break_end
								;;

							# 查看容器日志
							12)
								read -p "请输入容器名: " dockername
								docker logs $dockername
								break_end
								;;

							# 查看容器网络
							13)
								echo ""
								container_ids=$(docker ps -q)

								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								printf "%-25s %-25s %-25s\n" "容器名称" "网络名称" "IP地址"

								for container_id in $container_ids; do
									container_info=$(docker inspect --format '{{ .Name }}{{ range $network, $config := .NetworkSettings.Networks }} {{ $network }} {{ $config.IPAddress }}{{ end }}' "$container_id")

									container_name=$(echo "$container_info" | awk '{print $1}')
									network_info=$(echo "$container_info" | cut -d' ' -f2-)

									while IFS= read -r line; do
										network_name=$(echo "$line" | awk '{print $1}')
										ip_address=$(echo "$line" | awk '{print $2}')

										printf "%-20s %-20s %-15s\n" "$container_name" "$network_name" "$ip_address"
									done <<< "$network_info"
								done

								break_end
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

					# Docker 镜像管理
          			4)
						while true; do
							clear
							echo -e "${baizise}${bold}                  Docker 镜像列表               ${jiacu}"
							docker image ls
							echo ""
							echo "镜像操作"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "1. 获取指定镜像             3. 删除指定镜像"
							echo "2. 更新指定镜像             4. 删除所有镜像"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "0. 返回上一级选单"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							read -p "请输入你的选择: " sub_choice

							case $sub_choice in
								# 获取指定镜像
								1)
									read -p "请输入镜像名: " dockername
									docker pull $dockername
									;;

								# 更新指定镜像
								2)
									read -p "请输入镜像名: " dockername
									docker pull $dockername
									;;

								# 删除指定镜像
								3)
									read -p "请输入镜像名: " dockername
									docker rmi -f $dockername
									;;

								# 删除所有镜像
								4)
									read -p "$(echo -e "${red}确定删除所有镜像吗？(Y/N): ${normal}")" choice

									case "$choice" in
										[Yy])
											docker rmi -f $(docker images -q)
											;;
										[Nn])
											;;
										*)
											echo "无效的选择，请输入 Y 或 N。"
											;;
									esac
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

					# ToDo 需要看一下格式效果
					# Docker 网络管理
          			5)
						while true; do
							clear
							echo -e "${baizise}${bold}                  Docker 网络列表               ${jiacu}"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							docker network ls
							echo ""

							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							container_ids=$(docker ps -q)
							printf "%-25s %-25s %-25s\n" "容器名称" "网络名称" "IP地址"

							for container_id in $container_ids; do
								container_info=$(docker inspect --format '{{ .Name }}{{ range $network, $config := .NetworkSettings.Networks }} {{ $network }} {{ $config.IPAddress }}{{ end }}' "$container_id")

								container_name=$(echo "$container_info" | awk '{print $1}')
								network_info=$(echo "$container_info" | cut -d' ' -f2-)

									while IFS= read -r line; do
										network_name=$(echo "$line" | awk '{print $1}')
										ip_address=$(echo "$line" | awk '{print $2}')

										printf "%-20s %-20s %-15s\n" "$container_name" "$network_name" "$ip_address"
									done <<< "$network_info"
							done

							echo ""
							echo -e "${cyan}网络操作${normal}"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "1. 创建网络"
							echo "2. 加入网络"
							echo "3. 退出网络"
							echo "4. 删除网络"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "0. 返回上一级选单"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							read -p "请输入你的选择: " sub_choice

							case $sub_choice in
								# 创建网络
								1)
									read -p "设置新网络名: " dockernetwork
									docker network create $dockernetwork
									;;

								# 加入网络
								2)
									read -p "加入网络名: " dockernetwork
									read -p "那些容器加入该网络: " dockername
									docker network connect $dockernetwork $dockername
									echo ""
									;;

								# 退出网络
								3)
									read -p "退出网络名: " dockernetwork
									read -p "那些容器退出该网络: " dockername
									docker network disconnect $dockernetwork $dockername
									echo ""
									;;

								# 删除网络
								4)
									read -p "请输入要删除的网络名: " dockernetwork
									docker network rm $dockernetwork
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

					# Docker 卷管理
          			6)
						while true; do
							clear
							echo -e "${baizise}${bold}                  Docker 卷列表                 ${jiacu}"
							docker volume ls
							echo ""
							echo "卷操作"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "1. 创建新卷"
							echo "2. 删除卷"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "0. 返回上一级选单"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							read -p "请输入你的选择: " sub_choice

							case $sub_choice in
								# 创建新卷
								1)
									read -p "设置新卷名: " dockerjuan
									docker volume create $dockerjuan
									;;

								# 删除卷
								2)
									read -p "输入删除卷名: " dockerjuan
									docker volume rm $dockerjuan
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

					# 清理无用的 Docker 容器和镜像网络数据卷
          			7)
						clear
						read -p "$(echo -e "${yellow}确定清理无用的镜像容器网络吗？(Y/N): ${normal}")" choice

						case "$choice" in
							[Yy])
								docker system prune -af --volumes
								;;

							[Nn])
								;;

							*)
								echo "无效的选择，请输入 Y 或 N。"
								;;
						esac
						;;

					# 卸载 Docker 环境
          			8)
						clear
						read -p "$(echo -e "${red}确定卸载 docker 环境吗？(Y/N): ${normal}")" choice

						case "$choice" in
							[Yy])
								docker rm $(docker ps -a -q) && docker rmi $(docker images -q) && docker network prune
								remove docker > /dev/null 2>&1
								;;

							[Nn])
								;;

							*)
								echo "无效的选择，请输入 Y 或 N。"
								;;
						esac
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

		# WARP 管理
# 		7)
#			clear
#			install wget
#			wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh [option] [lisence/url/token]
#	    	;;

		# 测试脚本合集
		8)
			while true; do
				clear
				echo -e "${baizise}${bold}                  ▶ 测试脚本合集                ${jiacu}"
				echo ""
				echo -e "${cyan}${bold}-------------IP 及解锁状态检测----------------${jiacu}"
				echo "1. ChatGPT 解锁状态检测"
				echo "2. Region 流媒体解锁测试"
#				echo "3. yeahwu 流媒体解锁检测"
#				echo "4. xykt_IP 质量体检脚本"
				echo ""
				echo -e "${cyan}${bold}-------------网络测试-------------------------${jiacu}"
#      			echo "11. besttrace 三网回程延迟路由测试"
				echo "11. Speedtest 网络带宽测速"
				echo "12. mtr_trace 三网回程线路测试"
				echo "13. Superspeed 三网测速"
#				echo "14. nxtrace 快速回程测试脚本"
#				echo "15. nxtrace 指定 IP 回程测试脚本"
#				echo "16. ludashi2020 三网线路测试"
				echo ""
				echo -e "${cyan}${bold}-------------硬件性能测试---------------------${jiacu}"
				echo "21. yabs 性能测试"
				echo "22. icu/gb5 CPU 性能测试脚本"
				echo ""
				echo -e "${cyan}${bold}-------------综合性测试-----------------------${jiacu}"
				echo "31. bench 性能测试"
				echo "32. spiritysdx 融合怪测评"
				echo "41. Disk Test 硬盘&系统综合测试（杜甫测试）"
				echo ""
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "0. 返回主菜单"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				read -p "请输入你的选择: " sub_choice

				case $sub_choice in
					# ChatGPT 解锁状态检测
					1)
						clear
						bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
#						留存删库备用
#						bash <(curl -Ls https://raw.githubusercontent.com/oliver556/sh/main/third_party/openai.sh)
						;;

					# Region 流媒体解锁测试
					2)
						clear
						bash <(curl -L -s check.unlock.media)
						;;

					# yeahwu 流媒体解锁检测
#					3)
#						clear
#						install wget
#						wget -qO- https://github.com/yeahwu/check/raw/main/check.sh | bash
#						;;

					# xykt_IP 质量体检脚本
#		          	4)
#        		    	clear
#              			bash <(curl -Ls IP.Check.Place)
#              			;;

					# speedtest Server network 网络测速工具
					11)
						clear
						speed_test_tool
						;;

					# besttrace 三网回程延迟路由测试
#          			11)
#              			clear
#              			install wget
#              			wget -qO- git.io/besttrace | bash
#              			;;

					# mtr_trace 三网回程线路测试
					12)
						clear
						curl https://raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
#						留存删库备用
#						curl https://raw.githubusercontent.com/oliver556/sh/main/third_party/mtr_trace.sh | bash
						;;

					# Superspeed 三网测速
					13)
						clear
						bash <(curl -Lso- https://git.io/superspeed_uxh)
#						留存删库备用
#						bash <(curl -Lso- https://raw.githubusercontent.com/oliver556/sh/main/third_party/superspeed_uxh)
						;;

					# nxtrace 快速回程测试脚本
#					14)
#					  	clear
#					  	curl nxtrace.org/nt |bash
#					  	nexttrace --fast-trace --tcp
#					  	;;

					# nxtrace 指定 IP 回程测试脚本
#					15)
#						clear
#
#						echo -e "${baizise}${bold}                  可参考的 IP 列表              ${jiacu}"
#						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
#						echo "北京电信: 219.141.136.12"
#						echo "北京联通: 202.106.50.1"
#						echo "北京移动: 221.179.155.161"
#						echo "上海电信: 202.96.209.133"
#						echo "上海联通: 210.22.97.1"
#						echo "上海移动: 211.136.112.200"
#						echo "广州电信: 58.60.188.222"
#						echo "广州联通: 210.21.196.6"
#						echo "广州移动: 120.196.165.24"
#						echo "成都电信: 61.139.2.69"
#						echo "成都联通: 119.6.6.6"
#						echo "成都移动: 211.137.96.205"
#						echo "湖南电信: 36.111.200.100"
#						echo "湖南联通: 42.48.16.100"
#						echo "湖南移动: 39.134.254.6"
#						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
#
#						read -p "输入一个指定IP: " testip
#						curl nxtrace.org/nt |bash
#						nexttrace $testip
#						;;

					# ludashi2020 三网线路测试
#          			16)
#              			clear
#              			curl https://raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
#              			;;

					# yabs 性能测试
					21)
						clear
						new_swap=1024
						add_swap
						curl -sL yabs.sh | bash -s -- -i -5
						;;

					# icu/gb5 CPU 性能测试脚本
					22)
						clear
						new_swap=1024
						add_swap
						bash <(curl -sL bash.icu/gb5)
						;;

					# bench 性能测试
					31)
						clear
						curl -Lso- bench.sh | bash
#					  	留存删库备用
#					  	curl -Lso- https://raw.githubusercontent.com/oliver556/sh/main/third_party/bench.sh | bash;
						;;

					# spiritysdx 融合怪测评
					32)
						clear
						curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
						;;

					# Disk Test 硬盘&系统综合测试（杜甫测试）
					41)
						clear
						curl -sS -O https://raw.githubusercontent.com/oliver556/sh/main/third_party/A.sh && chmod +x A.sh && ./A.sh
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

		# 甲骨文云脚本合集
		9)
			while true; do
				clear
				echo -e "${baizise}${bold}                  ▶ 甲骨文云脚本合集            ${jiacu}"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "1. 安装闲置机器活跃脚本"
				echo "2. 卸载闲置机器活跃脚本"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "3. DD 重装系统脚本"
				echo "4. R 探长开机脚本"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "5. 开启 ROOT 密码登录模式"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "0. 返回主菜单"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				read -p "请输入你的选择: " sub_choice

				case $sub_choice in
					# 安装闲置机器活跃脚本
					1)
						clear
						echo "活跃脚本: CPU 占用 10-20% 内存占用 15% "
						read -p "确定安装吗？(Y/N): " choice

						case "$choice" in
							[Yy])
								# 检查系统中是否已经安装了 docker 和 docker-compose
								install_docker

								docker run -itd --name=lookbusy --restart=always \
												-e TZ=Asia/Shanghai \
												-e CPU_UTIL=10-20 \
												-e CPU_CORE=1 \
												-e MEM_UTIL=15 \
												-e SPEEDTEST_INTERVAL=120 \
												fogforest/lookbusy
								;;

							[Nn])
								;;

							*)
								echo "无效的选择，请输入 Y 或 N。"
								;;
						esac
						;;

					# 卸载闲置机器活跃脚本
					2)
						clear
						docker rm -f lookbusy
						docker rmi fogforest/lookbusy
						;;

					# DD 重装系统脚本
					3)
						clear
						echo "请备份数据，将为你重装系统，预计花费 15 分钟。"
						read -p "确定继续吗？(Y/N): " choice

						case "$choice" in
							[Yy])
								while true; do
									read -p "请选择要重装的系统:  1. Debian12 | 2. Ubuntu20.04 : " sys_choice

									case "$sys_choice" in
										1)
											xitong="-d 12"
											break  # 结束循环
										;;

										2)
											xitong="-u 20.04"
											break  # 结束循环
											;;

										*)
											echo "无效的选择，请重新输入。"
											;;
									esac
								done

								read -p "请输入你重装后的密码: " vpspasswd
								install wget
								bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') $xitong -v 64 -p $vpspasswd -port 22
								;;

							[Nn])
								echo "已取消"
								;;

							*)
								echo "无效的选择，请输入 Y 或 N。"
								;;
						esac
						;;

					# R 探长开机脚本
					4)
						clear
						echo "该功能处于开发阶段，敬请期待！"
						;;

					# 开启 ROOT 密码登录模式
					5)
						clear
						add_sshpasswd
						;;

					#
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

		# LDNMP 建站
  		10)
			while true; do
				clear
				echo -e "${baizise}${bold}                  LDNMP 建站                    ${jiacu}"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo  "1. 安装 LDNMP 环境"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo  "2. 安装 WordPress"
#				echo  "3. 安装 Discuz 论坛"
#				echo  "4. 安装可道云桌面"
#				echo  "5. 安装苹果 CMS 网站"
#				echo  "6. 安装独角数发卡网"
#				echo  "7. 安装 flarum 论坛网站"
#				echo  "8. 安装 typecho 轻量博客网站"
				echo  "20. 自定义动态站点"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo  "21. 仅安装 nginx"
				echo  "22. 站点重定向"
				echo  "23. 站点反向代理"
				echo  "24. 自定义静态站点"
#				echo  "25. 安装 Bitwarden 密码管理平台"
#				echo  "26. 安装 Halo 博客网站"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo  "31. 站点数据管理"
				echo  "32. 备份全站数据"
				echo  "33. 定时远程备份"
				echo  "34. 还原全站数据"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo  "35. 站点防御程序"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo  "36. 优化 LDNMP 环境"
				echo  "37. 更新 LDNMP 环境"
				echo  "38. 卸载 LDNMP 环境"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo  "0. 返回主菜单"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				read -p "请输入你的选择: " sub_choice

				case $sub_choice in
					# 安装 LDNMP 环境
					1)
						root_use
						# 检查端口
						check_port
						# 安装依赖（wget socat unzip tar）
						install_dependency
						# 检查系统中是否已经安装了 docker 和 docker-compose
						install_docker
						# 安装 certbot 工具
						install_certbot

						# 创建必要的目录和文件
						cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/redis web/log/nginx && touch web/docker-compose.yml

						wget -O /home/web/nginx.conf https://raw.githubusercontent.com/oliver556/sh/main/nginx/nginx10.conf
						wget -O /home/web/conf.d/default.conf https://raw.githubusercontent.com/oliver556/sh/main/nginx/default10.conf
						# 创建自签名的 SSL 证书并将其存储在指定的目录中
						default_server_ssl

						# 下载 docker-compose.yml 文件并进行替换
						wget -O /home/web/docker-compose.yml https://raw.githubusercontent.com/oliver556/sh/main/docker/LNMP-docker-compose-10.yml

						dbrootpasswd=$(openssl rand -base64 16) && dbuse=$(openssl rand -hex 4) && dbusepasswd=$(openssl rand -base64 8)

						# 在 docker-compose.yml 文件中进行替换
						sed -i "s#webroot#$dbrootpasswd#g" /home/web/docker-compose.yml
						sed -i "s#kejilionYYDS#$dbusepasswd#g" /home/web/docker-compose.yml
						sed -i "s#kejilion#$dbuse#g" /home/web/docker-compose.yml

						# 更新 LDNMP 环境
						install_ldnmp
						;;

					# 安装 WordPress
					2)
						clear
						# wordpress
						webname="WordPress"

						# 检查是否安装 LDNMP 环境
						ldnmp_install_status
						# 获取 IP，及收集用户输入要解析的域名
						add_yuming
						# 获取 SSL/TLS 证书
						install_ssltls
						#
						add_db

						wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/oliver556/sh/main/nginx/wordpress.com.conf
						sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

						cd /home/web/html
						mkdir $yuming
						cd $yuming
						wget -O latest.zip https://cn.wordpress.org/latest-zh_CN.zip
						unzip latest.zip
						rm latest.zip

						echo "define('FS_METHOD', 'direct'); define('WP_REDIS_HOST', 'redis'); define('WP_REDIS_PORT', '6379');" >> /home/web/html/$yuming/wordpress/wp-config-sample.php

						# 设置 nginx、php 目录权限并重启
						restart_ldnmp

						# 获取域名地址，进行提示
						ldnmp_web_on

						echo "数据库名: $dbname"
						echo "用户名: $dbuse"
						echo "密码: $dbusepasswd"
						echo "数据库地址: mysql"
						echo "表前缀: wp_"

						# 检查 docker、证书申请 状态
						nginx_status
					;;

					# 安装 Discuz 论坛
#					3)
#						clear
#						# Discuz 论坛
#						webname="Discuz 论坛"
#						ldnmp_install_status
#						add_yuming
#						install_ssltls
#						add_db
#
#						wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/discuz.com.conf
#
#						sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
#
#						cd /home/web/html
#						mkdir $yuming
#						cd $yuming
#						wget https://github.com/kejilion/Website_source_code/raw/main/Discuz_X3.5_SC_UTF8_20230520.zip
#						unzip -o Discuz_X3.5_SC_UTF8_20230520.zip
#						rm Discuz_X3.5_SC_UTF8_20230520.zip
#
#						restart_ldnmp
#
#						ldnmp_web_on
#						echo "数据库地址: mysql"
#						echo "数据库名: $dbname"
#						echo "用户名: $dbuse"
#						echo "密码: $dbusepasswd"
#						echo "表前缀: discuz_"
#						nginx_status
#						;;

					# 安装可道云桌面
#					4)
#						clear
#						# 可道云桌面
#						webname="可道云桌面"
#						# 检查是否安装 LDNMP 环境
#						ldnmp_install_status
#						# 获取 IP，及收集用户输入要解析的域名
#						add_yuming
#						# 获取 SSL/TLS 证书
#						install_ssltls
#						#
#						add_db
#
#						wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/kdy.com.conf
#						sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
#
#						cd /home/web/html
#						mkdir $yuming
#						cd $yuming
#						wget https://github.com/kalcaddle/kodbox/archive/refs/tags/1.42.04.zip
#						unzip -o 1.42.04.zip
#						rm 1.42.04.zip
#
#						restart_ldnmp
#
#						ldnmp_web_on
#						echo "数据库地址: mysql"
#						echo "用户名: $dbuse"
#						echo "密码: $dbusepasswd"
#						echo "数据库名: $dbname"
#						echo "redis主机: redis"
#						nginx_status
#						;;

					# 安装苹果 CMS 网站
#					5)
#						clear
#						# 苹果 CMS
#						webname="苹果 CMS"
#						# 检查是否安装 LDNMP 环境
#						ldnmp_install_status
#						# 获取 IP，及收集用户输入要解析的域名
#						add_yuming
#						# 获取 SSL/TLS 证书
#						install_ssltls
#						#
#						add_db
#
#						wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/maccms.com.conf
#
#						sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
#
#						cd /home/web/html
#						mkdir $yuming
#						cd $yuming
#						# wget https://github.com/magicblack/maccms_down/raw/master/maccms10.zip && unzip maccms10.zip && rm maccms10.zip
#						wget https://github.com/magicblack/maccms_down/raw/master/maccms10.zip && unzip maccms10.zip && mv maccms10-*/* . && rm -r maccms10-* && rm maccms10.zip
#						cd /home/web/html/$yuming/template/ && wget https://github.com/kejilion/Website_source_code/raw/main/DYXS2.zip && unzip DYXS2.zip && rm /home/web/html/$yuming/template/DYXS2.zip
#						cp /home/web/html/$yuming/template/DYXS2/asset/admin/Dyxs2.php /home/web/html/$yuming/application/admin/controller
#						cp /home/web/html/$yuming/template/DYXS2/asset/admin/dycms.html /home/web/html/$yuming/application/admin/view/system
#						mv /home/web/html/$yuming/admin.php /home/web/html/$yuming/vip.php && wget -O /home/web/html/$yuming/application/extra/maccms.php https://raw.githubusercontent.com/kejilion/Website_source_code/main/maccms.php
#
#						restart_ldnmp
#
#						ldnmp_web_on
#						echo "数据库地址: mysql"
#						echo "数据库端口: 3306"
#						echo "数据库名: $dbname"
#						echo "用户名: $dbuse"
#						echo "密码: $dbusepasswd"
#						echo "数据库前缀: mac_"
#						echo "------------------------"
#						echo "安装成功后登录后台地址"
#						echo "https://$yuming/vip.php"
#						nginx_status
#						;;

					# 安装独角数发卡网
					6)
						clear
						# 独脚数卡
						webname="独脚数卡"
						ldnmp_install_status
						add_yuming
						install_ssltls
						add_db

						wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/dujiaoka.com.conf

						sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

						cd /home/web/html
						mkdir $yuming
						cd $yuming
						wget https://github.com/assimon/dujiaoka/releases/download/2.0.6/2.0.6-antibody.tar.gz && tar -zxvf 2.0.6-antibody.tar.gz && rm 2.0.6-antibody.tar.gz

						restart_ldnmp


						ldnmp_web_on
						echo "数据库地址: mysql"
						echo "数据库端口: 3306"
						echo "数据库名: $dbname"
						echo "用户名: $dbuse"
						echo "密码: $dbusepasswd"
						echo ""
						echo "redis地址: redis"
						echo "redis密码: 默认不填写"
						echo "redis端口: 6379"
						echo ""
						echo "网站url: https://$yuming"
						echo "后台登录路径: /admin"
						echo "------------------------"
						echo "用户名: admin"
						echo "密码: admin"
						echo "------------------------"
						echo "登录时右上角如果出现红色error0请使用如下命令: "
						echo "我也很气愤独角数卡为啥这么麻烦，会有这样的问题！"
						echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"
						nginx_status
						;;

					# 安装 flarum 论坛网站
#					7)
#						clear
#						# flarum论坛
#						webname="flarum论坛"
#						ldnmp_install_status
#						add_yuming
#						install_ssltls
#						add_db
#
#						wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/flarum.com.conf
#						sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
#
#						cd /home/web/html
#						mkdir $yuming
#						cd $yuming
#
#						docker exec php sh -c "php -r \"copy('https://getcomposer.org/installer', 'composer-setup.php');\""
#						docker exec php sh -c "php composer-setup.php"
#						docker exec php sh -c "php -r \"unlink('composer-setup.php');\""
#						docker exec php sh -c "mv composer.phar /usr/local/bin/composer"
#
#						docker exec php composer create-project flarum/flarum /var/www/html/$yuming
#						docker exec php sh -c "cd /var/www/html/$yuming && composer require flarum-lang/chinese-simplified"
#						docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/polls"
#
#						restart_ldnmp
#
#
#						ldnmp_web_on
#						echo "数据库地址: mysql"
#						echo "数据库名: $dbname"
#						echo "用户名: $dbuse"
#						echo "密码: $dbusepasswd"
#						echo "表前缀: flarum_"
#						echo "管理员信息自行设置"
#						nginx_status
#						;;

					# 安装 typecho 轻量博客网站
#					8)
#						clear
#						# typecho
#						webname="typecho"
#						ldnmp_install_status
#						add_yuming
#						install_ssltls
#						add_db
#
#						wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/typecho.com.conf
#						sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
#
#						cd /home/web/html
#						mkdir $yuming
#						cd $yuming
#						wget -O latest.zip https://github.com/typecho/typecho/releases/latest/download/typecho.zip
#						unzip latest.zip
#						rm latest.zip
#
#						restart_ldnmp
#
#
#						clear
#						ldnmp_web_on
#						echo "数据库前缀: typecho_"
#						echo "数据库地址: mysql"
#						echo "用户名: $dbuse"
#						echo "密码: $dbusepasswd"
#						echo "数据库名: $dbname"
#						nginx_status
#						;;

					# 自定义动态站点
					20)
						clear
						webname="PHP 动态站点"
						ldnmp_install_status
						add_yuming
						install_ssltls
						add_db

						wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/oliver556/sh/main/php/index_php.conf
						sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

						cd /home/web/html
						mkdir $yuming
						cd $yuming

						clear
						echo -e "[${yellow}1/5${normal}] 上传PHP源码"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						echo "目前只允许上传 zip 格式的源码包，请将源码包放到 /home/web/html/${yuming} 目录下"
						read -p "也可以输入下载链接，远程下载源码包，直接回车将跳过远程下载： " url_download

						if [ -n "$url_download" ]; then
							wget "$url_download"
						fi

						unzip $(ls -t *.zip | head -n 1)
						rm -f $(ls -t *.zip | head -n 1)

						clear
						echo -e "[${yellow}2/5${normal}] index.php 所在路径"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						find "$(realpath .)" -name "index.php" -print

						read -p "请输入 index.php 的路径，类似（/home/web/html/$yuming/wordpress/）： " index_lujing

						sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
						sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

						clear
						echo -e "[${yellow}3/5${normal}] 请选择 PHP 版本"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						read -p "1. php 最新版 | 2. php7.4 : " pho_v
						case "$pho_v" in
							#  php 最新版
							1)
								sed -i "s#php:9000#php:9000#g" /home/web/conf.d/$yuming.conf
								PHP_Version="php"
								;;
							# php7.4
							2)
								sed -i "s#php:9000#php74:9000#g" /home/web/conf.d/$yuming.conf
								PHP_Version="php74"
								;;
							*)
								echo "无效的选择，请重新输入。"
								;;
						esac


						clear
						echo -e "[${yellow}4/5${normal}] 安装指定扩展"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						echo "已经安装的扩展"
						docker exec php php -m

						read -p "$(echo -e "输入需要安装的扩展名称，如 ${yellow}SourceGuardian imap ftp${normal} 等等。直接回车将跳过安装 ： ")" php_extensions
						if [ -n "$php_extensions" ]; then
							docker exec $PHP_Version install-php-extensions $php_extensions
						fi


						clear
						echo -e "[${yellow}5/5${normal}] 编辑站点配置"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						echo "按任意键继续，可以详细设置站点配置，如伪静态等内容"
						read -n 1 -s -r -p ""
						install nano
						nano /home/web/conf.d/$yuming.conf

						# 设置 nginx、php 目录权限并重启
						restart_ldnmp

						# 获取域名地址，进行提示
						ldnmp_web_on
						prefix="web$(shuf -i 10-99 -n 1)_"
						echo "数据库地址: mysql"
						echo "数据库名: $dbname"
						echo "用户名: $dbuse"
						echo "密码: $dbusepasswd"
						echo "表前缀: $prefix"
						echo "管理员登录信息自行设置"
						# 检查 docker、证书申请 状态
						nginx_status
						;;

					# 仅安装 nginx
					21)
						root_use
						check_port
						install_dependency
						install_docker
						install_certbot

						cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/redis web/log/nginx

						wget -O /home/web/nginx.conf https://raw.githubusercontent.com/oliver556/sh/main/nginx/nginx10.conf
						wget -O /home/web/conf.d/default.conf https://raw.githubusercontent.com/oliver556/sh/main/nginx/default10.conf

						default_server_ssl

						docker rm -f nginx >/dev/null 2>&1
						docker rmi nginx nginx:alpine >/dev/null 2>&1
						docker run -d --name nginx --restart always -p 80:80 -p 443:443 -p 443:443/udp -v /home/web/nginx.conf:/etc/nginx/nginx.conf -v /home/web/conf.d:/etc/nginx/conf.d -v /home/web/certs:/etc/nginx/certs -v /home/web/html:/var/www/html -v /home/web/log/nginx:/var/log/nginx nginx:alpine

						clear
						nginx_version=$(docker exec nginx nginx -v 2>&1)
						nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
						echo -e "${green}nginx 已安装完成${normal}"
						echo -e "当前版本: ${yellow}v$nginx_version${normal}"
						echo ""
						;;

					# 站点重定向
					22)
						clear
						webname="站点重定向"
						nginx_install_status
						ip_address
						add_yuming
						read -p "请输入跳转域名: " reverseproxy

						install_ssltls

						wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/oliver556/sh/main/nginx/rewrite.conf
						sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
						sed -i "s/baidu.com/$reverseproxy/g" /home/web/conf.d/$yuming.conf

						docker restart nginx

						# 输出建站 IP
						nginx_web_on
						# 检查 docker、证书申请 状态
						nginx_status
						;;

					# 站点反向代理
					23)
						clear
						webname="站点反向代理"
						nginx_install_status
						ip_address
						add_yuming
						read -p "请输入你的反代IP: " reverseproxy
						read -p "请输入你的反代端口: " port

						install_ssltls

						wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/oliver556/sh/main/nginx/reverse-proxy.conf
						sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
						sed -i "s/0.0.0.0/$reverseproxy/g" /home/web/conf.d/$yuming.conf
						sed -i "s/0000/$port/g" /home/web/conf.d/$yuming.conf

						docker restart nginx

						# 输出建站 IP
						nginx_web_on
						# 检查 docker、证书申请 状态
						nginx_status
						;;

					# 自定义静态站点
					24)
						clear
						webname="静态站点"
						nginx_install_status
						add_yuming
						install_ssltls

						wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/oliver556/sh/main/nginx/html.conf
						sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

						cd /home/web/html
						mkdir $yuming
						cd $yuming


						clear
						echo -e "[${yellow}1/2${normal}] 上传静态源码"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						echo "目前只允许上传 zip 格式的源码包，请将源码包放到 /home/web/html/${yuming} 目录下"
						read -p "也可以输入下载链接，远程下载源码包，直接回车将跳过远程下载： " url_download

						if [ -n "$url_download" ]; then
							wget "$url_download"
						fi

						unzip $(ls -t *.zip | head -n 1)
						rm -f $(ls -t *.zip | head -n 1)

						clear
						echo -e "[${yellow}2/2${normal}] index.html 所在路径"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						find "$(realpath .)" -name "index.html" -print

						read -p "请输入 index.html 的路径，类似（/home/web/html/$yuming/index/）： " index_lujing

						sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
						sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

						docker exec nginx chmod -R 777 /var/www/html
						docker restart nginx

						nginx_web_on
						nginx_status
						;;

					# 安装 Bitwarden 密码管理平台
#					25)
#						clear
#						webname="Bitwarden"
#						nginx_install_status
#						add_yuming
#						install_ssltls
#
#						docker run -d \
#							--name bitwarden \
#							--restart always \
#							-p 3280:80 \
#							-v /home/web/html/$yuming/bitwarden/data:/data \
#							vaultwarden/server
#						duankou=3280
#
#						reverse_proxy
#
#						nginx_web_on
#						nginx_status
#						;;

					# 安装 Halo 博客网站
#					26)
#						clear
#						webname="halo"
#						nginx_install_status
#						add_yuming
#						install_ssltls
#
#						docker run -d --name halo --restart always -p 8010:8090 -v /home/web/html/$yuming/.halo2:/root/.halo2 halohub/halo:2
#						duankou=8010
#						reverse_proxy
#
#						nginx_web_on
#						nginx_status
#						;;

					# 站点数据管理
					31)
						root_use
						while true; do
							clear
							echo -e "${baizise}${bold}                  LDNMP 环境                    ${jiacu}"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							# 获取当前环境中 Nginx、MySQL、PHP 和 Redis 的版本信息
							ldnmp_v

							# ls -t /home/web/conf.d | sed 's/\.[^.]*$//'
							echo "${green}站点信息                      证书到期时间${normal}"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
#							ToDo 下面会报错找不到路径文件
							for cert_file in /home/web/certs/*_cert.pem; do
								domain=$(basename "$cert_file" | sed 's/_cert.pem//')
								if [ -n "$domain" ]; then
									expire_date=$(openssl x509 -noout -enddate -in "$cert_file" | awk -F'=' '{print $2}')
									formatted_date=$(date -d "$expire_date" '+%Y-%m-%d')
									printf "%-30s%s\n" "$domain" "$formatted_date"
								fi
							done

#							certs_dir="/home/web/certs"
#							if [ -d "$certs_dir" ]; then
#								find "$certs_dir" -name '*_cert.pem' -type f | while read -r cert_file; do
#								domain=$(basename "$cert_file" | sed 's/_cert.pem//' 2>/dev/null || echo "")
#								if [ -n "$domain" ]; then
#									expire_date=$(openssl x509 -noout -enddate -in "$cert_file" | awk -F'=' '{print \$2}')
#									formatted_date=$(date -d "$expire_date" '+%Y-%m-%d')
#									printf "%-30s%s\n" "$domain" "$formatted_date"
#								fi
#								done
#							else
#								echo "找不到证书目录: $certs_dir"
#								echo "找不到 PEM 证书文件。."
#						  	fi

							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo ""
							echo -e "${green}数据库信息${normal}"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
							docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2> /dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys"

							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo ""
							echo -e "${green}站点目录${jiacu}"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo -e "数据 ${grey}/home/web/html${normal}     证书 ${grey}/home/web/certs${normal}     配置 ${grey}/home/web/conf.d${normal}"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo ""
							echo -e "${green}操作${normal}"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "1. 申请/更新域名证书               2. 更换站点域名"
							echo "3. 清理站点缓存                    4. 查看站点分析报告"
							echo "5. 查看全局配置                    6. 查看站点配置"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "7. 删除指定站点                    8. 删除指定数据库"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "0. 返回上一级选单"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							read -p "请输入你的选择: " sub_choice

							case $sub_choice in
								# 申请/更新域名证书"
								1)
									read -p "请输入你的域名: " yuming
									install_ssltls
									;;

								# 更换站点域名
								2)
									read -p "请输入旧域名: " oddyuming
									read -p "请输入新域名: " yuming
									install_ssltls
									mv /home/web/conf.d/$oddyuming.conf /home/web/conf.d/$yuming.conf
									sed -i "s/$oddyuming/$yuming/g" /home/web/conf.d/$yuming.conf
									mv /home/web/html/$oddyuming /home/web/html/$yuming

									rm /home/web/certs/${oddyuming}_key.pem
									rm /home/web/certs/${oddyuming}_cert.pem

									docker restart nginx
									;;

								# 清理站点缓存
								3)
									docker exec -it nginx rm -rf /var/cache/nginx
									docker restart nginx
									docker exec php php -r 'opcache_reset();'
									docker restart php
									docker exec php74 php -r 'opcache_reset();'
									docker restart php74
									;;

								# 查看站点分析报告
								4)
									install goaccess
									goaccess --log-format=COMBINED /home/web/log/nginx/access.log
									;;

								# 查看全局配置
								5)
									install nano
									nano /home/web/nginx.conf
									docker restart nginx
									;;

								# 查看站点配置
								6)
									read -p "查看站点配置，请输入你的域名: " yuming
									install nano
									nano /home/web/conf.d/$yuming.conf
									docker restart nginx
									;;

								# 删除指定站点
								7)
									read -p "删除站点数据目录，请输入你的域名: " yuming
									rm -r /home/web/html/$yuming
									rm /home/web/conf.d/$yuming.conf
									rm /home/web/certs/${yuming}_key.pem
									rm /home/web/certs/${yuming}_cert.pem
									docker restart nginx
									;;

								# 删除指定数据库
								8)
									read -p "删除站点数据库，请输入数据库名: " shujuku
									dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
									docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE $shujuku;" 2> /dev/null
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

					# 备份全站数据
					32)
						clear
						cd /home/ && tar czvf web_$(date +"%Y%m%d%H%M%S").tar.gz web

						while true; do
							clear
							read -p "要传送文件到远程服务器吗？(Y/N): " choice
							case "$choice" in
								[Yy])
									read -p "请输入远端服务器 IP:  " remote_ip
									if [ -z "$remote_ip" ]; then
										echo "错误: 请输入远端服务器 IP。"
										continue
									fi

									latest_tar=$(ls -t /home/*.tar.gz | head -1)

									if [ -n "$latest_tar" ]; then
										ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
										sleep 2  # 添加等待时间
										scp -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
										echo "文件已传送至远程服务器 home 目录。"
									else
										echo "未找到要传送的文件。"
									fi
									break
									;;
								[Nn])
									break
									;;

								*)
									echo "无效的选择，请输入 Y 或 N。"
									;;
							esac
						done
					;;

					# 定时远程备份
					33)
						clear
						read -p "输入远程服务器 IP: " useip
						read -p "输入远程服务器密码: " usepasswd

						cd ~
						wget -O ${useip}_beifen.sh https://raw.githubusercontent.com/oliver556/sh/main/beifen.sh > /dev/null 2>&1
						chmod +x ${useip}_beifen.sh

						sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
						sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						echo "1. 每周备份                 2. 每天备份"
						read -p "请输入你的选择: " dingshi

						case $dingshi in
							# 每周备份
							1)
								read -p "选择每周备份的星期几 (0-6，0 代表星期日): " weekday
								(crontab -l ; echo "0 0 * * $weekday ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
								;;

							# 每天备份
							2)
								read -p "选择每天备份的时间（小时，0-23）: " hour
								(crontab -l ; echo "0 $hour * * * ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
								;;
							*)
								break  # 跳出
								;;
						esac

						install sshpass
					;;

					# 还原全站数据
					34)
						root_use
						cd /home/ && ls -t /home/*.tar.gz | head -1 | xargs -I {} tar -xzf {}
						check_port
						install_dependency
						install_docker
						install_certbot

						install_ldnmp
					;;

					# 站点防御程序
					35)
						if docker inspect fail2ban &>/dev/null ; then
							while true; do
								clear
								echo -e "${baizise}${bold}                  服务器防御程序已启动          ${jiacu}"
								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								echo "1. 开启 SSH 防暴力破解              2. 关闭 SSH 防暴力破解"
								echo "3. 开启网站保护                   4. 关闭网站保护"
								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								echo "5. 查看 SSH 拦截记录                6. 查看网站拦截记录"
								echo "7. 查看防御规则列表               8. 查看日志实时监控"
								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								echo "11. 配置拦截参数"
								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								echo "21. cloudflare 模式"
								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								echo "99. 卸载防御程序"
								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								echo "0. 退出"
								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								read -p "请输入你的选择: " sub_choice

								case $sub_choice in
									# 开启 SSH 防暴力破解
									1)
										sed -i 's/false/true/g' /path/to/fail2ban/config/fail2ban/jail.d/alpine-ssh.conf
										sed -i 's/false/true/g' /path/to/fail2ban/config/fail2ban/jail.d/linux-ssh.conf
										sed -i 's/false/true/g' /path/to/fail2ban/config/fail2ban/jail.d/centos-ssh.conf
										f2b_status
										;;

									# 关闭 SSH 防暴力破解
									2)
										sed -i 's/true/false/g' /path/to/fail2ban/config/fail2ban/jail.d/alpine-ssh.conf
										sed -i 's/true/false/g' /path/to/fail2ban/config/fail2ban/jail.d/linux-ssh.conf
										sed -i 's/true/false/g' /path/to/fail2ban/config/fail2ban/jail.d/centos-ssh.conf
										f2b_status
										;;

									# 开启网站保护
									3)
										sed -i 's/false/true/g' /path/to/fail2ban/config/fail2ban/jail.d/nginx-docker-cc.conf
										f2b_status
										;;

									# 关闭网站保护
									4)
										sed -i 's/true/false/g' /path/to/fail2ban/config/fail2ban/jail.d/nginx-docker-cc.conf
										f2b_status
										;;

									# 查看 SSH 拦截记录
									5)
										echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
										f2b_sshd
										echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
										;;

									# 查看网站拦截记录
									6)
										echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
										xxx=fail2ban-nginx-cc
										f2b_status_xxx
										echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
										xxx=docker-nginx-bad-request
										f2b_status_xxx
										echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
										xxx=docker-nginx-botsearch
										f2b_status_xxx
										echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
										xxx=docker-nginx-http-auth
										f2b_status_xxx
										echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
										xxx=docker-nginx-limit-req
										f2b_status_xxx
										echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
										xxx=docker-php-url-fopen
										f2b_status_xxx
										echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
										;;

									# 查看防御规则列表
									7)
										docker exec -it fail2ban fail2ban-client status
										;;

									# 查看日志实时监控
									8)
										tail -f /path/to/fail2ban/config/log/fail2ban/fail2ban.log
										;;

									# 卸载防御程序
									99)
										docker rm -f fail2ban
										rm -rf /path/to/fail2ban
										echo "Fail2Ban 防御程序已卸载"
										break
										;;

									# 配置拦截参数
									11)
										install nano
										nano /path/to/fail2ban/config/fail2ban/jail.d/nginx-docker-cc.conf
										f2b_status

										break
										;;

									# cloudflare 模式
									21)
										echo "到 cf 后台右上角我的个人资料，选择左侧 API 令牌，获取 Global API Key"
										echo "https://dash.cloudflare.com/login"
										read -p "输入 CF 的账号: " cfuser
										read -p "输入 CF 的 Global API Key: " cftoken

										wget -O /home/web/conf.d/default.conf https://raw.githubusercontent.com/kejilion/nginx/main/default11.conf
										docker restart nginx

										cd /path/to/fail2ban/config/fail2ban/jail.d/
										curl -sS -O https://raw.githubusercontent.com/oliver556/sh/main/config/fail2ban/nginx-docker-cc.conf

										cd /path/to/fail2ban/config/fail2ban/action.d
										curl -sS -O https://raw.githubusercontent.com/oliver556/sh/main/config/fail2ban/cloudflare-docker.conf

										# ToDo
										sed -i "s/kejilion@outlook.com/$cfuser/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
										sed -i "s/APIKEY00000/$cftoken/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
										f2b_status

										echo "已配置 cloudflare 模式，可在 cf 后台，站点-安全性-事件中查看拦截记录"
										;;

										0)
											break
											;;

										*)
											echo "无效的选择，请重新输入。"
											;;
								esac
								break_end

							done

						elif [ -x "$(command -v fail2ban-client)" ] ; then
							clear
							echo "卸载旧版 fail2ban"
							read -p "确定继续吗？(Y/N): " choice
							case "$choice" in
								[Yy])
									remove fail2ban
									rm -rf /etc/fail2ban
									echo -e "${green}Fail2Ban 防御程序已卸载${normal}"
									;;

								[Nn])
									echo "已取消"
									;;
								*)
									echo "无效的选择，请输入 Y 或 N。"
									;;
							esac

						else
							clear
							install_docker

							docker rm -f nginx
							wget -O /home/web/nginx.conf https://raw.githubusercontent.com/oliver556/sh/main/nginx/nginx10.conf
							wget -O /home/web/conf.d/default.conf https://raw.githubusercontent.com/oliver556/sh/main/nginx/default10.conf
							default_server_ssl
							docker run -d --name nginx --restart always --network web_default -p 80:80 -p 443:443 -p 443:443/udp -v /home/web/nginx.conf:/etc/nginx/nginx.conf -v /home/web/conf.d:/etc/nginx/conf.d -v /home/web/certs:/etc/nginx/certs -v /home/web/html:/var/www/html -v /home/web/log/nginx:/var/log/nginx nginx:alpine
							docker exec -it nginx chmod -R 777 /var/www/html

							f2b_install_sshd

							cd /path/to/fail2ban/config/fail2ban/filter.d
							curl -sS -O https://raw.githubusercontent.com/oliver556/sh/main/config/fail2ban/fail2ban-nginx-cc.conf
							cd /path/to/fail2ban/config/fail2ban/jail.d/
							curl -sS -O https://raw.githubusercontent.com/oliver556/sh/main/config/fail2ban/nginx-docker-cc.conf
							sed -i "/cloudflare/d" /path/to/fail2ban/config/fail2ban/jail.d/nginx-docker-cc.conf

							cd ~
							f2b_status

							echo "防御程序已开启"
						fi
						;;

					# 优化 LDNMP 环境
					36)
						while true; do
							clear
							echo -e "${baizise}${bold}                  优化 LDNMP 环境               ${jiacu}"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "1. 标准模式              2. 高性能模式 (推荐 2H2G 以上)"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "0. 退出"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							read -p "请输入你的选择: " sub_choice

							case $sub_choice in
								# 标准模式
								1)
									# nginx 调优
									sed -i 's/worker_connections.*/worker_connections 1024;/' /home/web/nginx.conf

									# php 调优
									# ToDo optimized_php.ini 该脚本为空
									wget -O /home/optimized_php.ini https://raw.githubusercontent.com/oliver556/sh/main/php/optimized_php.ini
									docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
									docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
									rm -rf /home/optimized_php.ini

									# php 调优
									wget -O /home/www.conf https://raw.githubusercontent.com/oliver556/sh/main/nginx/www-1.conf
									docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
									docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
									rm -rf /home/www.conf

									# mysql 调优
									# ToDo custom_mysql_config-1.cnf 该脚本为空
									wget -O /home/custom_mysql_config.cnf https://raw.githubusercontent.com/oliver556/sh/main/mysql/custom_mysql_config-1.cnf
									docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
									rm -rf /home/custom_mysql_config.cnf

									docker restart nginx
									docker restart php
									docker restart php74
									docker restart mysql

									echo -e "${green}LDNMP 环境已设置成 标准模式${normal}"

									;;

								# 高性能模式 (推荐 2H2G 以上)
								2)

									# nginx 调优
									sed -i 's/worker_connections.*/worker_connections 10240;/' /home/web/nginx.conf

									# php 调优
									wget -O /home/www.conf https://raw.githubusercontent.com/oliver556/sh/main/nginx/www.conf
									docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
									docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
									rm -rf /home/www.conf

									# mysql 调优
									wget -O /home/custom_mysql_config.cnf https://raw.githubusercontent.com/oliver556/sh/main/mysql/custom_mysql_config.cnf
									docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
									rm -rf /home/custom_mysql_config.cnf

									docker restart nginx
									docker restart php
									docker restart php74
									docker restart mysql

									echo -e "${green}LDNMP 环境已设置成 高性能模式${normal}"

									;;

								0)
									break
									;;

								*)
									echo "无效的选择，请重新输入。"
									;;
							esac
							break_end

						done
						;;

					# 更新 LDNMP 环境
					37)
						root_use
						docker rm -f nginx php php74 mysql redis
						docker rmi nginx nginx:alpine php:fpm php:fpm-alpine php:7.4.33-fpm php:7.4-fpm-alpine mysql redis redis:alpine

						check_port
						install_dependency
						install_docker
						install_ldnmp
						;;


					# 卸载 LDNMP 环境
					38)
						root_use

						read -p "$(echo -e "强烈建议${red}先备份全部网站数据${normal}，再卸载 LDNMP 环境。确定删除所有网站数据吗？(Y/N): ")" choice

						case "$choice" in
							[Yy])
								docker rm -f nginx php php74 mysql redis
								docker rmi nginx nginx:alpine php:fpm php:fpm-alpine php:7.4.33-fpm php:7.4-fpm-alpine mysql redis redis:alpine
								rm -rf /home/web
								;;

							[Nn])
								;;

							*)
								echo "无效的选择，请输入 Y 或 N。"
								;;
						esac
						;;

					0)
						leon
						;;

					*)
						echo "无效的输入!"
				esac
				break_end

			done
			;;

		# 面板工具
		11)
			while true; do
				clear
				echo -e "${baizise}${bold}                  ▶ 面板工具                    ${jiacu}"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "1. 宝塔面板官方版                       2. aaPanel 宝塔国际版"
				echo "3. 1Panel 新一代管理面板                4. NginxProxyManager 可视化面板"
				echo "5. AList 多存储文件列表程序             6. Ubuntu 远程桌面网页版"
				echo "7. 哪吒探针 VPS 监控面板                8. QB 离线 BT 磁力下载面板"
				echo "9. Poste.io 邮件服务器程序              10. RocketChat 多人在线聊天系统"
				echo "11. 禅道项目管理软件                    12. 青龙面板定时任务管理平台"
				echo "13. Cloudreve 网盘                      14. 简单图床图片管理程序"
				echo "15. emby 多媒体管理系统                 16. Speedtest 测速面板"
				echo "17. AdGuardHome 去广告软件              18. onlyoffice 在线办公 OFFICE"
				echo "19. 雷池 WAF 防火墙面板                 20. portainer 容器管理面板"
				echo "21. VScode 网页版                       22. UptimeKuma 监控工具"
				echo "23. Memos 网页备忘录                     24. Webtop 远程桌面网页版"
				echo "25. Nextcloud 网盘                      26. QD-Today 定时任务管理框架"
				echo "27. Dockge 容器堆栈管理面板             28. LibreSpeed 测速工具"
				echo "29. searxng 聚合搜索站                  30. PhotoPrism 私有相册系统"
				echo "31. StirlingPDF 工具大全                32. drawio 免费的在线图表软件"
				echo "33. Sun-Panel 导航面板                  34. Pingvin-Share 文件分享平台"
				echo "35. 极简朋友圈                          36. LobeChatAI 聊天聚合网站"
				echo "37. MyIP 工具箱"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "51. PVE 开小鸡面板"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "0. 返回主菜单"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				read -p "请输入你的选择: " sub_choice

				case $sub_choice in
					# 宝塔面板官方版
					1)
						lujing="[ -d "/www/server/panel" ]"
						panelname="宝塔面板"

						gongneng1="bt"
						gongneng1_1=""
						gongneng2="curl -o bt-uninstall.sh http://download.bt.cn/install/bt-uninstall.sh > /dev/null 2>&1 && chmod +x bt-uninstall.sh && ./bt-uninstall.sh"
						gongneng2_1="chmod +x bt-uninstall.sh"
						gongneng2_2="./bt-uninstall.sh"

						panelurl="https://www.bt.cn/new/index.html"


						centos_mingling="wget -O install.sh https://download.bt.cn/install/install_6.0.sh"
						centos_mingling2="sh install.sh ed8484bec"

						ubuntu_mingling="wget -O install.sh https://download.bt.cn/install/install-ubuntu_6.0.sh"
						ubuntu_mingling2="bash install.sh ed8484bec"

						install_panel
						;;

					# aaPanel 宝塔国际版
					2)

						lujing="[ -d "/www/server/panel" ]"
						panelname="aapanel"

						gongneng1="bt"
						gongneng1_1=""
						gongneng2="curl -o bt-uninstall.sh http://download.bt.cn/install/bt-uninstall.sh > /dev/null 2>&1 && chmod +x bt-uninstall.sh && ./bt-uninstall.sh"
						gongneng2_1="chmod +x bt-uninstall.sh"
						gongneng2_2="./bt-uninstall.sh"

						panelurl="https://www.aapanel.com/new/index.html"

						centos_mingling="wget -O install.sh http://www.aapanel.com/script/install_6.0_en.sh"
						centos_mingling2="bash install.sh aapanel"

						ubuntu_mingling="wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh"
						ubuntu_mingling2="bash install.sh aapanel"

						install_panel
						;;

					# 1Panel 新一代管理面板
					3)
						lujing="command -v 1pctl &> /dev/null"
						panelname="1Panel"

						gongneng1="1pctl user-info"
						gongneng1_1="1pctl update password"
						gongneng2="1pctl uninstall"
						gongneng2_1=""
						gongneng2_2=""

						panelurl="https://1panel.cn/"

						centos_mingling="curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh"
						centos_mingling2="sh quick_start.sh"

						ubuntu_mingling="curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh"
						ubuntu_mingling2="bash quick_start.sh"

						install_panel
						;;

					# NginxProxyManager 可视化面板
					4)
						docker_name="npm"
						docker_img="jc21/nginx-proxy-manager:latest"
						docker_port=81
						docker_rum="docker run -d \
													--name=$docker_name \
													-p 80:80 \
													-p 81:$docker_port \
													-p 443:443 \
													-v /home/docker/npm/data:/data \
													-v /home/docker/npm/letsencrypt:/etc/letsencrypt \
													--restart=always \
													$docker_img"
						docker_describe="如果您已经安装了其他面板工具或者 LDNMP 建站环境，建议先卸载，再安装 npm！"
						docker_url="官网介绍: https://nginxproxymanager.com/"
						docker_use="echo \"初始用户名: admin@example.com\""
						docker_passwd="echo \"初始密码: changeme\""

						docker_app

						;;

					# AList 多存储文件列表程序
					5)
						docker_name="alist"
						docker_img="xhofe/alist:latest"
						docker_port=5244
						docker_rum="docker run -d \
																--restart=always \
																-v /home/docker/alist:/opt/alist/data \
																-p 5244:5244 \
																-e PUID=0 \
																-e PGID=0 \
																-e UMASK=022 \
																--name="alist" \
																xhofe/alist:latest"
						docker_describe="一个支持多种存储，支持网页浏览和 WebDAV 的文件列表程序，由 gin 和 Solidjs 驱动"
						docker_url="官网介绍: https://alist.nn.ci/zh/"
						docker_use="docker exec -it alist ./alist admin random"
						docker_passwd=""

						docker_app
						;;

					# Ubuntu 远程桌面网页版
					6)
						docker_name="ubuntu-novnc"
						docker_img="fredblgr/ubuntu-novnc:20.04"
						docker_port=6080
						rootpasswd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
						docker_rum="docker run -d \
																--name ubuntu-novnc \
																-p 6080:80 \
																-v /home/docker/ubuntu-novnc:/workspace:rw \
																-e HTTP_PASSWORD=$rootpasswd \
																-e RESOLUTION=1280x720 \
																--restart=always \
																fredblgr/ubuntu-novnc:20.04"
						docker_describe="一个网页版 Ubuntu 远程桌面，挺好用的！"
						docker_url="官网介绍: https://hub.docker.com/r/fredblgr/ubuntu-novnc"
						docker_use="echo \"用户名: root\""
						docker_passwd="echo \"密码: $rootpasswd\""

						docker_app
						;;

					# 哪吒探针 VPS 监控面板
					7)
						clear
						curl -L https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh  -o nezha.sh && chmod +x nezha.sh
						./nezha.sh
						;;

					# QB 离线 BT 磁力下载面板
					8)

						docker_name="qbittorrent"
						docker_img="lscr.io/linuxserver/qbittorrent:latest"
						docker_port=8081
						docker_rum="docker run -d \
																	--name=qbittorrent \
																	-e PUID=1000 \
																	-e PGID=1000 \
																	-e TZ=Etc/UTC \
																	-e WEBUI_PORT=8081 \
																	-p 8081:8081 \
																	-p 6881:6881 \
																	-p 6881:6881/udp \
																	-v /home/docker/qbittorrent/config:/config \
																	-v /home/docker/qbittorrent/downloads:/downloads \
																	--restart unless-stopped \
																	lscr.io/linuxserver/qbittorrent:latest"
						docker_describe="qbittorrent 离线 BT 磁力下载服务"
						docker_url="官网介绍: https://hub.docker.com/r/linuxserver/qbittorrent"
						docker_use="sleep 3"
						docker_passwd="docker logs qbittorrent"

						docker_app
						;;

					# Poste.io 邮件服务器程序
					9)
						if docker inspect mailserver &>/dev/null; then

							clear
							echo -e "${green}poste.io 已安装，访问地址: ${normal}"
							yuming=$(cat /home/docker/mail.txt)
							echo "https://$yuming"
							echo ""

							echo -e "${cyan}应用操作${normal}"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "1. 更新应用             2. 卸载应用"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "0. 返回上一级选单"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							read -p "请输入你的选择: " sub_choice

							case $sub_choice in
								# 更新应用
								1)
									clear
									docker rm -f mailserver
									docker rmi -f analogic/poste.io

									yuming=$(cat /home/docker/mail.txt)
									docker run \
											--net=host \
											-e TZ=Europe/Prague \
											-v /home/docker/mail:/data \
											--name "mailserver" \
											-h "$yuming" \
											--restart=always \
											-d analogic/poste.io

									clear
									echo -e "${green}poste.io 已经安装完成${normal}"
									echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
									echo "您可以使用以下地址访问 poste.io:"
									echo "https://$yuming"
									echo ""
									;;

								# 卸载应用
								2)
									clear
									docker rm -f mailserver
									docker rmi -f analogic/poste.io
									rm /home/docker/mail.txt
									rm -rf /home/docker/mail
									echo -e "${green}应用已卸载${normal}"
									;;

								0)
									break  # 跳出循环，退出菜单
									;;

								*)
									break  # 跳出循环，退出菜单
									;;
							esac

						else
							clear
							install telnet

							clear
							echo ""
							echo "端口检测"
							port=25
							timeout=3

							if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
								echo -e "${lv}端口 $port 当前可用${bai}"
							else
								echo -e "${hong}端口 $port 当前不可用${bai}"
							fi

							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo ""


							echo "安装提示"
							echo -e "poste.i o一个邮件服务器，确保 ${yellow}80${normal} 和 ${yellow}443${normal} 端口没被占用，确保 ${yellow}25${normal} 端口开放"
							echo "官网介绍: https://hub.docker.com/r/analogic/poste.io"
							echo ""

							# 提示用户确认安装
							read -p "确定安装 poste.io 吗？(Y/N): " choice

							case "$choice" in
								[Yy])
									clear

									read -p "请设置邮箱域名 例如 mail.yuming.com : " yuming
									mkdir -p /home/docker      # 递归创建目录
									echo "$yuming" > /home/docker/mail.txt  # 写入文件
									echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
									ip_address
									echo "先解析这些DNS记录"
									echo "A           mail            $ipv4_address"
									echo "CNAME       imap            $yuming"
									echo "CNAME       pop             $yuming"
									echo "CNAME       smtp            $yuming"
									echo "MX          @               $yuming"
									echo "TXT         @               v=spf1 mx ~all"
									echo "TXT         ?               ?"
									echo ""
									echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
									echo "按任意键继续..."
									read -n 1 -s -r -p ""

									install_docker

									docker run \
											--net=host \
											-e TZ=Europe/Prague \
											-v /home/docker/mail:/data \
											--name "mailserver" \
											-h "$yuming" \
											--restart=always \
											-d analogic/poste.io

									clear
									echo -e "${green}poste.io 已经安装完成${normal}"
									echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
									echo "您可以使用以下地址访问 poste.io:"
									echo "https://$yuming"
									echo ""
									;;

								[Nn])
									;;

								*)
									;;
							esac
						fi
						;;

					# RocketChat 多人在线聊天系统
					10)
						if docker inspect rocketchat &>/dev/null; then
							clear
							echo -e "${green}rocket.chat 已安装，访问地址: ${normal}"
							ip_address
							echo "http:$ipv4_address:3897"
							echo ""

							echo -e "${cyan}应用操作${normal}"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "1. 更新应用             2. 卸载应用"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "0. 返回上一级选单"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							read -p "请输入你的选择: " sub_choice

							case $sub_choice in
								# 更新应用
								1)
									clear
									docker rm -f rocketchat
									docker rmi -f rocket.chat:6.3


									docker run --name rocketchat --restart=always -p 3897:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat

									clear
									ip_address
									echo -e "${green}rocket.chat 已经安装完成${normal}"
									echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
									echo "多等一会，您可以使用以下地址访问 rocket.chat:"
									echo "http:$ipv4_address:3897"
									echo ""
									;;

								# 卸载应用
								2)
									clear
									docker rm -f rocketchat
									docker rmi -f rocket.chat
									docker rmi -f rocket.chat:6.3
									docker rm -f db
									docker rmi -f mongo:latest
									# docker rmi -f mongo:6
									rm -rf /home/docker/mongo
									echo "应用已卸载"
									;;

								0)
									break  # 跳出循环，退出菜单
									;;

								*)
									break  # 跳出循环，退出菜单
									;;
							esac
						else
							clear
							echo -e "${cyan}安装提示${normal}"
							echo "rocket.chat 国外知名开源多人聊天系统"
							echo "官网介绍: https://www.rocket.chat"
							echo ""

							# 提示用户确认安装
							read -p "确定安装 rocket.chat 吗？(Y/N): " choice
							case "$choice" in
								[Yy])
								clear
								install_docker
								docker run --name db -d --restart=always \
										-v /home/docker/mongo/dump:/dump \
										mongo:latest --replSet rs5 --oplogSize 256
								sleep 1
								docker exec -it db mongosh --eval "printjson(rs.initiate())"
								sleep 5
								docker run --name rocketchat --restart=always -p 3897:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat

								clear

								ip_address
								echo ""
								echo -e "${green}rocket.chat 已经安装完成${normal}"
								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								echo "多等一会，您可以使用以下地址访问 rocket.chat:"
								echo "http:$ipv4_address:3897"
								echo ""
								;;

								[Nn])
									;;
								*)
									;;
							esac
						fi
						;;

					# 禅道项目管理软件
					11)
						docker_name="zentao-server"
						docker_img="idoop/zentao:latest"
						docker_port=82
						docker_rum="docker run -d -p 82:80 -p 3308:3306 \
															-e ADMINER_USER="root" -e ADMINER_PASSWD="password" \
															-e BIND_ADDRESS="false" \
															-v /home/docker/zentao-server/:/opt/zbox/ \
															--add-host smtp.exmail.qq.com:163.177.90.125 \
															--name zentao-server \
															--restart=always \
															idoop/zentao:latest"
						docker_describe="禅道是通用的项目管理软件"
						docker_url="官网介绍: https://www.zentao.net/"
						docker_use="echo \"初始用户名: admin\""
						docker_passwd="echo \"初始密码: 123456\""

						docker_app
						;;

					# 青龙面板定时任务管理平台
					12)
						docker_name="qinglong"
						docker_img="whyour/qinglong:latest"
						docker_port=5700
						docker_rum="docker run -d \
											-v /home/docker/qinglong/data:/ql/data \
											-p 5700:5700 \
											--name qinglong \
											--hostname qinglong \
											--restart unless-stopped \
											whyour/qinglong:latest"
						docker_describe="青龙面板是一个定时任务管理平台"
						docker_url="官网介绍: https://github.com/whyour/qinglong"
						docker_use=""
						docker_passwd=""
						docker_app
						;;

					# Cloudreve 网盘
					13)
						if docker inspect cloudreve &>/dev/null; then

						clear
						echo -e "${green}cloudreve 已安装，访问地址: ${normal}"
						ip_address
						echo "http:$ipv4_address:5212"
						echo ""

						echo -e "${cyan}应用操作${normal}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						echo "1. 更新应用             2. 卸载应用"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						echo "0. 返回上一级选单"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						read -p "请输入你的选择: " sub_choice

						case $sub_choice in
							# 更新应用
							1)
								clear
								docker rm -f cloudreve
								docker rmi -f cloudreve/cloudreve:latest
								docker rm -f aria2
								docker rmi -f p3terx/aria2-pro

								cd /home/ && mkdir -p docker/cloud && cd docker/cloud && mkdir temp_data && mkdir -vp cloudreve/{uploads,avatar} && touch cloudreve/conf.ini && touch cloudreve/cloudreve.db && mkdir -p aria2/config && mkdir -p data/aria2 && chmod -R 777 data/aria2
								curl -o /home/docker/cloud/docker-compose.yml https://raw.githubusercontent.com/oliver556/sh/main/docker/cloudreve-docker-compose.yml
								cd /home/docker/cloud/ && docker compose up -d

								clear
								echo ""
								echo -e "${green}cloudreve 已经安装完成${normal}"
								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								echo "您可以使用以下地址访问 cloudreve:"
								ip_address
								echo "http:$ipv4_address:5212"
								sleep 3
								docker logs cloudreve
								echo ""
								;;

							# 卸载应用
							2)
								clear
								docker rm -f cloudreve
								docker rmi -f cloudreve/cloudreve:latest
								docker rm -f aria2
								docker rmi -f p3terx/aria2-pro
								rm -rf /home/docker/cloud
								echo "应用已卸载"
								;;

							0)
								break  # 跳出循环，退出菜单
								;;

							*)
								break  # 跳出循环，退出菜单
								;;
						esac

					else

						clear
						echo ""
						echo -e "${cyan}安装提示${normal}"
						echo "cloudreve 是一个支持多家云存储的网盘系统"
						echo "官网介绍: https://cloudreve.org/"
						echo ""

						# 提示用户确认安装
						read -p "确定安装 cloudreve吗？(Y/N): " choice
						case "$choice" in
							[Yy])
							clear
							install_docker
							cd /home/ && mkdir -p docker/cloud && cd docker/cloud && mkdir temp_data && mkdir -vp cloudreve/{uploads,avatar} && touch cloudreve/conf.ini && touch cloudreve/cloudreve.db && mkdir -p aria2/config && mkdir -p data/aria2 && chmod -R 777 data/aria2
							curl -o /home/docker/cloud/docker-compose.yml https://raw.githubusercontent.com/oliver556/sh/main/docker/cloudreve-docker-compose.yml
							cd /home/docker/cloud/ && docker compose up -d

							clear
							echo -e "${green}cloudreve 已经安装完成${normal}"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "您可以使用以下地址访问 cloudreve:"
							ip_address
							echo "http:$ipv4_address:5212"
							sleep 3
							docker logs cloudreve
							echo ""

							;;

							[Nn])
								;;

							*)
								;;
						esac
					fi
					;;

					# 简单图床图片管理程序
					14)
						docker_name="easyimage"
						docker_img="ddsderek/easyimage:latest"
						docker_port=85
						docker_rum="docker run -d \
											--name easyimage \
											-p 85:80 \
											-e TZ=Asia/Shanghai \
											-e PUID=1000 \
											-e PGID=1000 \
											-v /home/docker/easyimage/config:/app/web/config \
											-v /home/docker/easyimage/i:/app/web/i \
											--restart unless-stopped \
											ddsderek/easyimage:latest"
						docker_describe="简单图床是一个简单的图床程序"
						docker_url="官网介绍: https://github.com/icret/EasyImages2.0"
						docker_use=""
						docker_passwd=""

						docker_app
						;;

					# emby 多媒体管理系统
					15)
						docker_name="emby"
						docker_img="linuxserver/emby:latest"
						docker_port=8096
						docker_rum="docker run -d --name=emby --restart=always \
												-v /homeo/docker/emby/config:/config \
												-v /homeo/docker/emby/share1:/mnt/share1 \
												-v /homeo/docker/emby/share2:/mnt/share2 \
												-v /mnt/notify:/mnt/notify \
												-p 8096:8096 -p 8920:8920 \
												-e UID=1000 -e GID=100 -e GIDLIST=100 \
												linuxserver/emby:latest"
						docker_describe="emby 是一个主从式架构的媒体服务器软件，可以用来整理服务器上的视频和音频，并将音频和视频流式传输到客户端设备"
						docker_url="官网介绍: https://emby.media/"
						docker_use=""
						docker_passwd=""
						docker_app
						;;

					# Speedtest 测速面板
					16)
						docker_name="looking-glass"
						docker_img="wikihostinc/looking-glass-server"
						docker_port=89
						docker_rum="docker run -d --name looking-glass --restart always -p 89:80 wikihostinc/looking-glass-server"
						docker_describe="Speedtest 测速面板是一个 VPS 网速测试工具，多项测试功能，还可以实时监控 VPS 进出站流量"
						docker_url="官网介绍: https://github.com/wikihost-opensource/als"
						docker_use=""
						docker_passwd=""
						docker_app
						;;

					# AdGuardHome 去广告软件
					17)
						docker_name="adguardhome"
						docker_img="adguard/adguardhome"
						docker_port=3000
						docker_rum="docker run -d \
														--name adguardhome \
														-v /home/docker/adguardhome/work:/opt/adguardhome/work \
														-v /home/docker/adguardhome/conf:/opt/adguardhome/conf \
														-p 53:53/tcp \
														-p 53:53/udp \
														-p 3000:3000/tcp \
														--restart always \
														adguard/adguardhome"
						docker_describe="AdGuardHome 是一款全网广告拦截与反跟踪软件，未来将不止是一个 DNS 服务器。"
						docker_url="官网介绍: https://hub.docker.com/r/adguard/adguardhome"
						docker_use=""
						docker_passwd=""

						docker_app
						;;

					# onlyoffice 在线办公 OFFICE
					18)
						docker_name="onlyoffice"
						docker_img="onlyoffice/documentserver"
						docker_port=8082
						docker_rum="docker run -d -p 8082:80 \
												--restart=always \
												--name onlyoffice \
												-v /home/docker/onlyoffice/DocumentServer/logs:/var/log/onlyoffice  \
												-v /home/docker/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data  \
												 onlyoffice/documentserver"
						docker_describe="onlyoffice 是一款开源的在线 office 工具，太强大了！"
						docker_url="官网介绍: https://www.onlyoffice.com/"
						docker_use=""
						docker_passwd=""
						docker_app
						;;

					# 雷池 WAF 防火墙面板
					19)
						if docker inspect safeline-tengine &>/dev/null; then

							clear
							echo -e "${green}雷池已安装，访问地址: ${normal}"
							ip_address
							echo "http:$ipv4_address:9443"
							echo ""

							echo -e "${cyan}应用操作${normal}"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "1. 更新应用             2. 卸载应用"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "0. 返回上一级选单"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							read -p "请输入你的选择: " sub_choice

							case $sub_choice in
								# 更新应用
								1)
									clear
									echo "暂不支持"
									echo ""
									;;

								# 卸载应用
								2)
									clear
									echo "cd 命令到安装目录下执行: docker compose down"
									echo ""
									;;

								0)
									break  # 跳出循环，退出菜单
									;;

								*)
									break  # 跳出循环，退出菜单
									;;
							esac

						else

							clear
							echo "安装提示"
							echo "雷池是长亭科技开发的 WAF 站点防火墙程序面板，可以反代站点进行自动化防御"
							echo -e "${yellow}80${normal} 和 ${yellow}443${normal} 端口不能被占用，无法与宝塔，1panel，npm，ldnmp 建站共存"
							echo "官网介绍: https://github.com/chaitin/safeline"
							echo ""

							# 提示用户确认安装
							read -p "确定安装吗？(Y/N): " choice
							case "$choice" in
								[Yy])
									clear
									install_docker
									bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"

									clear
									echo -e "${green}雷池 WAF 面板已经安装完成${normal}"
									echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
									echo "您可以使用以下地址访问:"
									ip_address
									echo "http:$ipv4_address:9443"
									echo ""
									;;

								[Nn])
									;;

								*)
									;;
							esac
						fi
						;;

					# portainer 容器管理面板
					20)
						docker_name="portainer"
						docker_img="portainer/portainer"
						docker_port=9050
						docker_rum="docker run -d \
										--name portainer \
										-p 9050:9000 \
										-v /var/run/docker.sock:/var/run/docker.sock \
										-v /home/docker/portainer:/data \
										--restart always \
										portainer/portainer"
						docker_describe="portainer 是一个轻量级的 docker 容器管理面板"
						docker_url="官网介绍: https://www.portainer.io/"
						docker_use=""
						docker_passwd=""
						docker_app
						;;

					# VScode 网页版
						21)
							docker_name="vscode-web"
							docker_img="codercom/code-server"
							docker_port=8180
							docker_rum="docker run -d -p 8180:8080 -v /home/docker/vscode-web:/home/coder/.local/share/code-server --name vscode-web --restart always codercom/code-server"
							docker_describe="VScode 是一款强大的在线代码编写工具"
							docker_url="官网介绍: https://github.com/coder/code-server"
							docker_use="sleep 3"
							docker_passwd="docker exec vscode-web cat /home/coder/.config/code-server/config.yaml"
							docker_app
							;;

					# UptimeKuma 监控工具
						22)
							docker_name="uptime-kuma"
							docker_img="louislam/uptime-kuma:latest"
							docker_port=3003
							docker_rum="docker run -d \
															--name=uptime-kuma \
															-p 3003:3001 \
															-v /home/docker/uptime-kuma/uptime-kuma-data:/app/data \
															--restart=always \
															louislam/uptime-kuma:latest"
							docker_describe="Uptime Kuma 易于使用的自托管监控工具"
							docker_url="官网介绍: https://github.com/louislam/uptime-kuma"
							docker_use=""
							docker_passwd=""
							docker_app
							;;

					# Memos 网页备忘录
						23)
							docker_name="memos"
							docker_img="ghcr.io/usememos/memos:latest"
							docker_port=5230
							docker_rum="docker run -d --name memos -p 5230:5230 -v /home/docker/memos:/var/opt/memos --restart always ghcr.io/usememos/memos:latest"
							docker_describe="Memos 是一款轻量级、自托管的备忘录中心"
							docker_url="官网介绍: https://github.com/usememos/memos"
							docker_use=""
							docker_passwd=""
							docker_app
							;;

					# Webtop 远程桌面网页版
					24)
						docker_name="webtop"
						docker_img="lscr.io/linuxserver/webtop:latest"
						docker_port=3083
						docker_rum="docker run -d \
													--name=webtop \
													--security-opt seccomp=unconfined \
													-e PUID=1000 \
													-e PGID=1000 \
													-e TZ=Etc/UTC \
													-e SUBFOLDER=/ \
													-e TITLE=Webtop \
													-e LC_ALL=zh_CN.UTF-8 \
													-e DOCKER_MODS=linuxserver/mods:universal-package-install \
													-e INSTALL_PACKAGES=font-noto-cjk \
													-p 3083:3000 \
													-v /home/docker/webtop/data:/config \
													-v /var/run/docker.sock:/var/run/docker.sock \
													--device /dev/dri:/dev/dri \
													--shm-size="1gb" \
													--restart unless-stopped \
													lscr.io/linuxserver/webtop:latest"

						docker_describe="webtop基于 Alpine、Ubuntu、Fedora 和 Arch 的容器，包含官方支持的完整桌面环境，可通过任何现代 Web 浏览器访问"
						docker_url="官网介绍: https://docs.linuxserver.io/images/docker-webtop/"
						docker_use=""
						docker_passwd=""
						docker_app
						;;

					# Nextcloud 网盘
					25)
						docker_name="nextcloud"
						docker_img="nextcloud:latest"
						docker_port=8989
						rootpasswd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
						docker_rum="docker run -d --name nextcloud --restart=always -p 8989:80 -v /home/docker/nextcloud:/var/www/html -e NEXTCLOUD_ADMIN_USER=nextcloud -e NEXTCLOUD_ADMIN_PASSWORD=$rootpasswd nextcloud"
						docker_describe="Nextcloud 拥有超过 400,000 个部署，是您可以下载的最受欢迎的本地内容协作平台"
						docker_url="官网介绍: https://nextcloud.com/"
						docker_use="echo \"账号: nextcloud  密码: $rootpasswd\""
						docker_passwd=""
						docker_app
						;;

					# QD-Today 定时任务管理框架
					26)
						docker_name="qd"
						docker_img="qdtoday/qd:latest"
						docker_port=8923
						docker_rum="docker run -d --name qd -p 8923:80 -v /home/docker/qd/config:/usr/src/app/config qdtoday/qd"
						docker_describe="QD-Today是一个HTTP请求定时任务自动执行框架"
						docker_url="官网介绍: https://qd-today.github.io/qd/zh_CN/"
						docker_use=""
						docker_passwd=""
						docker_app
						;;

					# Dockge 容器堆栈管理面板
					27)
						docker_name="dockge"
						docker_img="louislam/dockge:latest"
						docker_port=5003
						docker_rum="docker run -d --name dockge --restart unless-stopped -p 5003:5001 -v /var/run/docker.sock:/var/run/docker.sock -v /home/docker/dockge/data:/app/data -v  /home/docker/dockge/stacks:/home/docker/dockge/stacks -e DOCKGE_STACKS_DIR=/home/docker/dockge/stacks louislam/dockge"
						docker_describe="dockge 是一个可视化的 docker-compose 容器管理面板"
						docker_url="官网介绍: https://github.com/louislam/dockge"
						docker_use=""
						docker_passwd=""
						docker_app
						;;

					# LibreSpeed 测速工具
					28)
						docker_name="speedtest"
						docker_img="ghcr.io/librespeed/speedtest:latest"
						docker_port=6681
						docker_rum="docker run -d \
														--name speedtest \
														--restart always \
														-e MODE=standalone \
														-p 6681:80 \
														ghcr.io/librespeed/speedtest:latest"
						docker_describe="librespeed是用Javascript实现的轻量级速度测试工具，即开即用"
						docker_url="官网介绍: https://github.com/librespeed/speedtest"
						docker_use=""
						docker_passwd=""
						docker_app
						;;

					# searxng 聚合搜索站
					29)
						docker_name="searxng"
						docker_img="alandoyle/searxng:latest"
						docker_port=8700
						docker_rum="docker run --name=searxng \
														-d --init \
														--restart=unless-stopped \
														-v /home/docker/searxng/config:/etc/searxng \
														-v /home/docker/searxng/templates:/usr/local/searxng/searx/templates/simple \
														-v /home/docker/searxng/theme:/usr/local/searxng/searx/static/themes/simple \
														-p 8700:8080/tcp \
														alandoyle/searxng:latest"
						docker_describe="searxng 是一个私有且隐私的搜索引擎站点"
						docker_url="官网介绍: https://hub.docker.com/r/alandoyle/searxng"
						docker_use=""
						docker_passwd=""
						docker_app
						;;

					# PhotoPrism 私有相册系统
					30)
						docker_name="photoprism"
						docker_img="photoprism/photoprism:latest"
						docker_port=2342
						rootpasswd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
						docker_rum="docker run -d \
														--name photoprism \
														--restart always \
														--security-opt seccomp=unconfined \
														--security-opt apparmor=unconfined \
														-p 2342:2342 \
														-e PHOTOPRISM_UPLOAD_NSFW="true" \
														-e PHOTOPRISM_ADMIN_PASSWORD="$rootpasswd" \
														-v /home/docker/photoprism/storage:/photoprism/storage \
														-v /home/docker/photoprism/Pictures:/photoprism/originals \
														photoprism/photoprism"
						docker_describe="photoprism非常强大的私有相册系统"
						docker_url="官网介绍: https://www.photoprism.app/"
						docker_use="echo \"账号: admin  密码: $rootpasswd\""
						docker_passwd=""
						docker_app
						;;

					# 31. StirlingPDF 工具大全
					31)
						docker_name="s-pdf"
						docker_img="frooodle/s-pdf:latest"
						docker_port=8020
						docker_rum="docker run -d \
														--name s-pdf \
														--restart=always \
														 -p 8020:8080 \
														 -v /home/docker/s-pdf/trainingData:/usr/share/tesseract-ocr/5/tessdata \
														 -v /home/docker/s-pdf/extraConfigs:/configs \
														 -v /home/docker/s-pdf/logs:/logs \
														 -e DOCKER_ENABLE_SECURITY=false \
														 frooodle/s-pdf:latest"
						docker_describe="这是一个强大的本地托管基于 Web 的 PDF 操作工具，使用 docker，允许您对 PDF 文件执行各种操作，例如拆分合并、转换、重新组织、添加图像、旋转、压缩等。"
						docker_url="官网介绍: https://github.com/Stirling-Tools/Stirling-PDF"
						docker_use=""
						docker_passwd=""
						docker_app
						;;

					# drawio 免费的在线图表软件
					32)
						docker_name="drawio"
						docker_img="jgraph/drawio"
						docker_port=7080
						docker_rum="docker run -d --restart=always --name drawio -p 7080:8080 -v /home/docker/drawio:/var/lib/drawio jgraph/drawio"
						docker_describe="这是一个强大图表绘制软件。思维导图，拓扑图，流程图，都能画"
						docker_url="官网介绍: https://www.drawio.com/"
						docker_use=""
						docker_passwd=""
						docker_app
						;;

					# Sun-Panel 导航面板
					33)
						docker_name="sun-panel"
						docker_img="hslr/sun-panel"
						docker_port=3009
						docker_rum="docker run -d --restart=always -p 3009:3002 \
														-v /home/docker/sun-panel/conf:/app/conf \
														-v /home/docker/sun-panel/uploads:/app/uploads \
														-v /home/docker/sun-panel/database:/app/database \
														--name sun-panel \
														hslr/sun-panel"
						docker_describe="Sun-Panel服务器、NAS导航面板、Homepage、浏览器首页"
						docker_url="官网介绍: https://doc.sun-panel.top/zh_cn/"
						docker_use="echo \"账号: admin@sun.cc  密码: 12345678\""
						docker_passwd=""
						docker_app
						;;

					# Pingvin-Share 文件分享平台
					34)
						docker_name="pingvin-share"
						docker_img="stonith404/pingvin-share"
						docker_port=3060
						docker_rum="docker run -d \
														--name pingvin-share \
														--restart always \
														-p 3060:3000 \
														-v /home/docker/pingvin-share/data:/opt/app/backend/data \
														stonith404/pingvin-share"
						docker_describe="Pingvin Share 是一个可自建的文件分享平台，是 WeTransfer 的一个替代品"
						docker_url="官网介绍: https://github.com/stonith404/pingvin-share"
						docker_use=""
						docker_passwd=""
						docker_app
						;;

					# 极简朋友圈
					35)
						docker_name="moments"
						docker_img="kingwrcy/moments:latest"
						docker_port=8035
						docker_rum="docker run -d --restart unless-stopped \
														-p 8035:3000 \
														-v /home/docker/moments/data:/app/data \
														-v /etc/localtime:/etc/localtime:ro \
														-v /etc/timezone:/etc/timezone:ro \
														--name moments \
														kingwrcy/moments:latest"
						docker_describe="极简朋友圈，高仿微信朋友圈，记录你的美好生活"
						docker_url="官网介绍: https://github.com/kingwrcy/moments?tab=readme-ov-file"
						docker_use="echo \"账号: admin  密码: a123456\""
						docker_passwd=""
						docker_app
						;;

					# LobeChatAI 聊天聚合网站
					36)
						docker_name="lobe-chat"
						docker_img="lobehub/lobe-chat:latest"
						docker_port=8036
						docker_rum="docker run -d -p 8036:3210 \
														--name lobe-chat \
														--restart=always \
														lobehub/lobe-chat"
						docker_describe="LobeChat聚合市面上主流的AI大模型，ChatGPT/Claude/Gemini/Groq/Ollama"
						docker_url="官网介绍: https://github.com/lobehub/lobe-chat"
						docker_use=""
						docker_passwd=""
						docker_app
						;;

					# MyIP 工具箱
					37)
						docker_name="myip"
						docker_img="ghcr.io/jason5ng32/myip:latest"
						docker_port=8037
						docker_rum="docker run -d -p 8037:18966 --name myip --restart always ghcr.io/jason5ng32/myip:latest"
						docker_describe="是一个多功能 IP 工具箱，可以查看自己 IP 信息及连通性，用网页面板呈现"
						docker_url="官网介绍: https://github.com/jason5ng32/MyIP/blob/main/README_ZH.md"
						docker_use=""
						docker_passwd=""
						docker_app
						;;

					# 51. PVE 开小鸡面板
					51)
						clear
						curl -L https://raw.githubusercontent.com/oneclickvirt/pve/main/scripts/install_pve.sh -o install_pve.sh && chmod +x install_pve.sh && bash install_pve.sh
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

		# 我的工作区
		12)
			while true; do
				clear
				echo -e "${baizise}${bold}                  ▶ 我的工作区                  ${jiacu}"
				echo "系统将为你提供 5 个后台运行的工作区，你可以用来执行长时间的任务"
				echo "即使你断开 SSH，工作区中的任务也不会中断，非常方便！来试试吧！"
				echo -e "${yellow}注意: 进入工作区后使用 Ctrl + b 再单独按 d，退出工作区！normal{bai}"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "1. 1 号工作区"
				echo "2. 2 号工作区"
				echo "3. 3 号工作区"
				echo "4. 4 号工作区"
				echo "5. 5 号工作区"
				echo "6. 6 号工作区"
				echo "7. 7 号工作区"
				echo "8. 8 号工作区"
				echo "9. 9 号工作区"
				echo "10. 10 号工作区"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "99. 工作区状态"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "b. 卸载工作区"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "0. 返回主菜单"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				read -p "请输入你的选择: " sub_choice

				case $sub_choice in
					b)
						clear
						remove tmux
						;;
					1)
						clear
						install tmux
						SESSION_NAME="work1"
						tmux_run
						;;

					2)
						clear
						install tmux
						SESSION_NAME="work2"
						tmux_run
						;;

					3)
						clear
						install tmux
						SESSION_NAME="work3"
						tmux_run
						;;

					4)
						clear
						install tmux
						SESSION_NAME="work4"
						tmux_run
						;;

					5)
						clear
						install tmux
						SESSION_NAME="work5"
						tmux_run
						;;

					6)
						clear
						install tmux
						SESSION_NAME="work6"
						tmux_run
						;;

					7)
						clear
						install tmux
						SESSION_NAME="work7"
						tmux_run
						;;

					8)
						clear
						install tmux
						SESSION_NAME="work8"
						tmux_run
						;;

					9)
						clear
						install tmux
						SESSION_NAME="work9"
						tmux_run
						;;

					10)
						clear
						install tmux
						SESSION_NAME="work10"
						tmux_run
						;;

					99)
						clear
						install tmux
						tmux list-sessions
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
				echo -e "${baizise}${bold}                  ▶ 系统工具                    ${jiacu}"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "1. 设置脚本启动快捷键                  2. 修改登录密码"
				echo "3. ROOT 密码登录模式                   4. 安装 Python 最新版"
				echo "5. 开放所有端口                        6. 修改 SSH 连接端口"
				echo "7. 优化 DNS 地址                       8. 一键重装系统"
				echo "9. 禁用 ROOT 账户创建新账户            10. 切换优先 ipv4/ipv6"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "11. 查看端口占用状态                   12. 修改虚拟内存大小"
				echo "13. 用户管理                           14. 用户/密码生成器"
				echo "15. 系统时区调整                       16. 设置 BBR3 加速"
				echo "17. 防火墙高级管理器                   18. 修改主机名"
				echo "19. 切换系统更新源                     20. 定时任务管理"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "21. 本机 host 解析                     22. fail2banSSH 防御程序"
				echo "23. 限流自动关机                       24. ROOT 私钥登录模式"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "31. 留言板                             66. 一条龙系统调优"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "99. 重启服务器"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				echo "0. 返回主菜单"
				echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
				read -p "请输入你的选择: " sub_choice

				case $sub_choice in
					# 设置脚本启动快捷键
					1)
						clear
						read -p "请输入你的快捷按键: " kuaijiejian
						echo "alias $kuaijiejian='~/leon.sh'" >> ~/.bashrc
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
						add_sshpasswd
						;;

					# 安装 Python 最新版
					4)
						root_use

						# 系统检测
						OS=$(cat /etc/os-release | grep -o -E "Debian|Ubuntu|CentOS" | head -n 1)

						if [[ $OS == "Debian" || $OS == "Ubuntu" || $OS == "CentOS" ]]; then
							echo -e "检测到你的系统是 ${yellow}${OS}${normal}"
						else
							echo -e "${red}很抱歉，你的系统不受支持！${normal}"
							exit 1
						fi

						# 检测安装 Python3 的版本
						VERSION=$(python3 -V 2>&1 | awk '{print $2}')

						# 获取最新 Python3 版本
						PY_VERSION=$(curl -s https://www.python.org/ | grep "downloads/release" | grep -o 'Python [0-9.]*' | grep -o '[0-9.]*')

						# 卸载 Python3 旧版本
						if [[ $VERSION == "3"* ]]; then
							echo -e "${yellow}你的 Python3 版本是${normal}${red}${VERSION}${normal}，${yellow}最新版本是${normal}${red}${PY_VERSION}${normal}"
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
								echo -e "${yellow}已取消升级 Python3${normal}"
								exit 1
							fi
						else
							echo -e "${red}检测到没有安装 Python3。${normal}"
							read -p "是否确认安装最新版 Python3？默认安装 [Y/n]: " CONFIRM

							if [[ $CONFIRM != "n" ]]; then
								echo -e "${grey}开始安装最新版Python3...${normal}"
							else
								echo -e "${yellow}已取消安装 Python3${normal}"
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
							echo -e "${yellow}Python3 安装${green}成功，${normal}版本为: ${normal}${green}${PY_VERSION}${normal}"
						else
							clear
							echo -e "${red}Python3 安装失败！${normal}"
							exit 1
						fi
						cd /root/ && rm -rf Python-${PY_VERSION}.tgz && rm -rf Python-${PY_VERSION}
						;;

					# 开放所有端口
					5)
						root_use
						iptables_open
						remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
						echo "端口已全部开放"
						;;

					# 修改 SSH 连接端口
					6)
						root_use

						# 去掉 #Port 的注释
						sed -i 's/#Port/Port/' /etc/ssh/sshd_config

						# 读取当前的 SSH 端口号
						current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

						# 打印当前的 SSH 端口号
						echo "当前的 SSH 端口号是: $current_port"

						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"

						# 提示用户输入新的 SSH 端口号
						read -p "请输入新的 SSH 端口号: " new_port

						new_ssh_port

						;;

					# 优化 DNS 地址
					7)
						root_use
						echo -e "${cyan}当前 DNS 地址${normal}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						cat /etc/resolv.conf
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						echo ""
						# 询问用户是否要优化 DNS 设置
						read -p "是否要设置 DNS 地址？(y/n): " choice

						if [ "$choice" == "y" ]; then
							read -p "1. 国外 DNS 优化    2. 国内 DNS 优化    0. 退出  : " Limiting

							case "$Limiting" in
								# 国外 DNS 优化
								1)
									dns1_ipv4="1.1.1.1"
									dns2_ipv4="8.8.8.8"
									dns1_ipv6="2606:4700:4700::1111"
									dns2_ipv6="2001:4860:4860::8888"
									set_dns
									;;

								# 国内 DNS 优化
								2)
									dns1_ipv4="223.5.5.5"
									dns2_ipv4="183.60.83.19"
									dns1_ipv6="2400:3200::1"
									dns2_ipv6="2400:da00::6666"
									set_dns
									;;

								0)
									echo "已取消"
									;;

								*)
									echo "无效的选择，请输入 Y 或 N。"
									;;
							esac


						else
							echo "DNS 设置未更改"
						fi
						;;

					# 一键重装系统
					8)

						dd_xitong_2() {
							echo -e "任意键继续，重装后初始用户名: ${yellow}root${normal}  初始密码: ${yellow}LeitboGi0ro${normal}  初始端口: ${yellow}22${normal}"
							read -n 1 -s -r -p ""
							install wget
							wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh
						}

						dd_xitong_3() {
							echo -e "任意键继续，重装后初始用户名: ${yellow}Administrator${normal}  初始密码: ${yellow}Teddysun.com${normal}  初始端口: ${yellow}3389${normal}"
							read -n 1 -s -r -p ""
							install wget
							wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh
						}

						dd_xitong_4() {
							echo -e "任意键继续，重装后初始用户名: ${yellow}Administrator${normal}  初始密码: ${yellow}123@@@${normal}  初始端口: ${yellow}3389${normal}"
							read -n 1 -s -r -p ""
							install wget
							curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
						}


						root_use
						echo -e "${red}请备份数据${normal}，将为你重装系统，预计花费 15 分钟。"
						echo -e "${grey}感谢 MollyLau 的脚本支持！${normal}"
						read -p "确定继续吗？(Y/N): " choice

						case "$choice" in
							[Yy])
								while true; do

									echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
									echo "1. Debian 12"
									echo "2. Debian 11"
									echo "3. Debian 10"
									echo "4. Debian 9"
									echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
									echo "11. Ubuntu 24.04"
									echo "12. Ubuntu 22.04"
									echo "13. Ubuntu 20.04"
									echo "14. Ubuntu 18.04"
									echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
									echo "21. CentOS 9"
									echo "22. CentOS 8"
									echo "23. CentOS 7"
									echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
									echo "31. Alpine 3.19"
									echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
									echo "41. Windows 11"
									echo "42. Windows 10"
									echo "43. Windows 7"
									echo "44. Windows Server 2022"
									echo "45. Windows Server 2019"
									echo "46. Windows Server 2016"
									echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
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

										# # Debian 10
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

										# Windows 11
										41)
											dd_xitong_3
											bash InstallNET.sh -windows 11 -lang "cn"
											reboot
											exit
											;;

										# Windows 10
										42)
											dd_xitong_3
											bash InstallNET.sh -windows 10 -lang "cn"
											reboot
											exit
											;;

										# Windows 7
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
											echo "无效的选择，请重新输入。"
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
							echo -e "当前网络优先级设置: ${yellow}${bold}IPv4${normal} 优先"
						else
							echo -e "当前网络优先级设置: ${yellow}${bold}IPv6${normal} 优先"
						fi
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"

						echo ""
						echo "切换的网络优先级"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						echo "1. IPv4 优先          2. IPv6 优先"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						read -p "选择优先的网络: " choice

						case $choice in
							# IPv4 优先
							1)
								sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null 2>&1
								echo "已切换为 IPv4 优先"
								;;

							# IPv6 优先
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

							# 显示所有用户、用户权限、用户组和是否在sudoers中
							echo -e "${baizise}${bold}                  用户列表                      ${jiacu}"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"

							printf "%-24s %-34s %-20s %-10s\n" "用户名" "用户权限" "用户组" "sudo权限"

							while IFS=: read -r username _ userid groupid _ _ homedir shell; do
								groups=$(groups "$username" | cut -d : -f 2)
								sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
								printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
							done < /etc/passwd


							echo ""
							echo -e "${baizise}${bold}                  账户操作                      ${jiacu}"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "1. 创建普通账户             2. 创建高级账户"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "3. 赋予最高权限             4. 取消最高权限"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "5. 删除账号"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "0. 返回上一级选单"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							read -p "请输入你的选择: " sub_choice

							case $sub_choice in
								# 创建普通账户
								1)
									# 提示用户输入新用户名
									read -p "请输入新用户名: " new_username
									# 创建新用户并设置密码
									useradd -m -s /bin/bash "$new_username"
									passwd "$new_username"

									echo "操作已完成。"
									;;

								# 创建高级账户
								2)
									# 提示用户输入新用户名
									read -p "请输入新用户名: " new_username

									# 创建新用户并设置密码
									useradd -m -s /bin/bash "$new_username"
									passwd "$new_username"

									# 赋予新用户 sudo 权限
									echo "$new_username ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers

									echo "操作已完成。"
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
									# 从sudoers 文件中移除用户的 sudo 权限
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

						echo -e "${cyan}随机用户名${normal}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						for i in {1..5}; do
							username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
							echo "随机用户名 $i: $username"
						done

						echo ""
						echo "随机姓名"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
						last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

						# 生成 5 个随机用户姓名
						for i in {1..5}; do
							first_name_index=$((RANDOM % ${#first_names[@]}))
							last_name_index=$((RANDOM % ${#last_names[@]}))
							user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
							echo "随机用户姓名 $i: $user_name"
						done

						echo ""
						echo "随机UUID"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						for i in {1..5}; do
							uuid=$(cat /proc/sys/kernel/random/uuid)
							echo "随机UUID $i: $uuid"
						done

						echo ""
						echo "16 位随机密码"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						for i in {1..5}; do
							password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
							echo "随机密码 $i: $password"
						done

						echo ""
						echo "32 位随机密码"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
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
							clear
							echo ""
							echo -e "${baizise}${bold}                  系统时间信息                  ${jiacu}"
							echo ""

							# 获取当前系统时区
							timezone=$(current_timezone)

							# 获取当前系统时间
							current_time=$(date +"%Y-%m-%d %H:%M:%S")

							# 显示时区和时间
							echo -e "当前系统时区: ${cyan}$timezone${normal}"
							echo -e "当前系统时间: ${cyan}$current_time${normal}"

							echo ""
							echo -e "${baizise}${bold}                  时区切换                      ${jiacu}"
							echo -e "${cyan}${bold}亚洲--------------------------------------------${jiacu}"
							echo "1. 中国上海时间              2. 中国香港时间"
							echo "3. 日本东京时间              4. 韩国首尔时间"
							echo "5. 新加坡时间                6. 印度加尔各答时间"
							echo "7. 阿联酋迪拜时间            8. 澳大利亚悉尼时间"
							echo -e "${cyan}${bold}欧洲--------------------------------------------${jiacu}"
							echo "11. 英国伦敦时间             12. 法国巴黎时间"
							echo "13. 德国柏林时间             14. 俄罗斯莫斯科时间"
							echo "15. 荷兰尤特赖赫特时间       16. 西班牙马德里时间"
							echo -e "${cyan}${bold}美洲--------------------------------------------${jiacu}"
							echo "21. 美国西部时间             22. 美国东部时间"
							echo "23. 加拿大时间               24. 墨西哥时间"
							echo "25. 巴西时间                 26. 阿根廷时间"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "0. 返回上一级选单"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
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
						root_use
						if dpkg -l | grep -q 'linux-xanmod'; then

							while true; do
								kernel_version=$(uname -r)
								echo "您已安装 xanmod 的 BBRv3 内核"
								echo "当前内核版本: $kernel_version"

								echo ""
								echo -e "${baizise}${bold}                  内核管理                      ${jiacu}"
								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								echo "1. 更新 BBRv3 内核              2. 卸载 BBRv3 内核"
								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								echo "0. 返回上一级选单"
								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								read -p "请输入你的选择: " sub_choice

								case $sub_choice in
									# 更新 BBRv3 内核
									1)
										apt purge -y 'linux-*xanmod1*'
										update-grub

										wget -qO - https://raw.githubusercontent.com/oliver556/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

										# 步骤3：添加存储库
										echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

										version=$(wget -q https://raw.githubusercontent.com/oliver556/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

										apt update -y
										apt install -y linux-xanmod-x64v$version

										echo "XanMod 内核已更新。重启后生效"
										rm -f /etc/apt/sources.list.d/xanmod-release.list
										rm -f check_x86-64_psabi.sh*

										server_reboot
										;;

									# 卸载 BBRv3 内核
									2)
										apt purge -y 'linux-*xanmod1*'
										update-grub
										echo -e "${green}XanMod 内核已卸载。重启后生效${normal}"
										server_reboot
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

							clear
							echo "请备份数据，将为你升级 Linux 内核开启 BBR3"
							echo "官网介绍: https://xanmod.org/"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "仅支持 Debian/Ubuntu 仅支持 x86_64 架构"
							echo "VPS 是 512M 内存的，请提前添加 1G 虚拟内存，防止因内存不足失联！"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							read -p "确定继续吗？(Y/N): " choice

							case "$choice" in
								[Yy])
									if [ -r /etc/os-release ]; then
										. /etc/os-release
										if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
											echo "当前环境不支持，仅支持 Debian 和 Ubuntu 系统"
											break
										fi
									else
										echo "无法确定操作系统类型"
										break
									fi

									# 检查系统架构
									arch=$(dpkg --print-architecture)
									if [ "$arch" != "amd64" ]; then
									 echo "当前环境不支持，仅支持 x86_64 架构"
										break
									fi

									new_swap=1024
									add_swap
									install wget gnupg

									wget -qO - https://raw.githubusercontent.com/oliver556/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

									# 步骤3：添加存储库
									echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

									version=$(wget -q https://raw.githubusercontent.com/oliver556/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

									apt update -y
									apt install -y linux-xanmod-x64v$version

									# 步骤5：启用 BBR3
									cat > /etc/sysctl.conf << EOF
net.core.default_qdisc=fq_pie
net.ipv4.tcp_congestion_control=bbr
EOF
									sysctl -p
									echo -e "${green}XanMod 内核安装并 BBR3 启用成功。重启后生效${normal}"
									rm -f /etc/apt/sources.list.d/xanmod-release.list
									rm -f check_x86-64_psabi.sh*
									server_reboot
									;;

								[Nn])
								  echo "已取消"
								  ;;

								*)
								  echo "无效的选择，请输入 Y 或 N。"
								  ;;
							esac
						fi
					  ;;

					# 防火墙高级管理器
					17)
						root_use

						if dpkg -l | grep -q iptables-persistent; then
						while true; do
							echo "防火墙已安装"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							iptables -L INPUT

							echo ""
							echo "防火墙管理"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "1. 开放指定端口              2. 关闭指定端口"
							echo "3. 开放所有端口              4. 关闭所有端口"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "5. IP 白名单                  6. IP 黑名单"
							echo "7. 清除指定IP"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "9. 卸载防火墙"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "0. 返回上一级选单"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							read -p "请输入你的选择: " sub_choice

							case $sub_choice in
								# 开放指定端口
								1)
									read -p "请输入开放的端口号: " o_port
									sed -i "/COMMIT/i -A INPUT -p tcp --dport $o_port -j ACCEPT" /etc/iptables/rules.v4
									sed -i "/COMMIT/i -A INPUT -p udp --dport $o_port -j ACCEPT" /etc/iptables/rules.v4
									iptables-restore < /etc/iptables/rules.v4
									;;

								# 关闭指定端口
								2)
									read -p "请输入关闭的端口号: " c_port
									sed -i "/--dport $c_port/d" /etc/iptables/rules.v4
									iptables-restore < /etc/iptables/rules.v4
									;;

								# 开放所有端口
								3)
									current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

									cat > /etc/iptables/rules.v4 << EOF
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A FORWARD -i lo -j ACCEPT
-A INPUT -p tcp --dport $current_port -j ACCEPT
COMMIT
EOF
									iptables-restore < /etc/iptables/rules.v4
									;;

									# 关闭所有端口
									4)
										current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

										cat > /etc/iptables/rules.v4 << EOF
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A FORWARD -i lo -j ACCEPT
-A INPUT -p tcp --dport $current_port -j ACCEPT
COMMIT
EOF
										iptables-restore < /etc/iptables/rules.v4
										;;

									# IP 白名单
									5)
										read -p "请输入放行的IP: " o_ip
										sed -i "/COMMIT/i -A INPUT -s $o_ip -j ACCEPT" /etc/iptables/rules.v4
										iptables-restore < /etc/iptables/rules.v4
										;;

									# IP 黑名单
									6)
										read -p "请输入封锁的IP: " c_ip
										sed -i "/COMMIT/i -A INPUT -s $c_ip -j DROP" /etc/iptables/rules.v4
										iptables-restore < /etc/iptables/rules.v4
										;;

									# 清除指定 IP
									7)
										read -p "请输入清除的IP: " d_ip
										sed -i "/-A INPUT -s $d_ip/d" /etc/iptables/rules.v4
										iptables-restore < /etc/iptables/rules.v4
										;;

									# 卸载防火墙
									9)
										remove iptables-persistent
										rm /etc/iptables/rules.v4
										break
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
						clear
						echo "将为你安装防火墙，该防火墙仅支持 Debian/Ubuntu"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						read -p "确定继续吗？(Y/N): " choice

						case "$choice" in
							[Yy])
								if [ -r /etc/os-release ]; then
								. /etc/os-release
									if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
										echo "当前环境不支持，仅支持 Debian 和 Ubuntu 系统"
										break
									fi
								else
									echo "无法确定操作系统类型"
									break
								fi

								clear
								iptables_open
								remove iptables-persistent ufw
								rm /etc/iptables/rules.v4

								apt update -y && apt install -y iptables-persistent

								current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

								cat > /etc/iptables/rules.v4 << EOF
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A FORWARD -i lo -j ACCEPT
-A INPUT -p tcp --dport $current_port -j ACCEPT
COMMIT
EOF

								iptables-restore < /etc/iptables/rules.v4
								systemctl enable netfilter-persistent
								echo -e "${green}防火墙安装完成${normal}"
								;;

							[Nn])
								echo "已取消"
								;;
							*)
								echo "无效的选择，请输入 Y 或 N。"
								;;
						esac
					fi
					;;

					# 修改主机名
					18)
						root_use
						current_hostname=$(hostname)
						echo "当前主机名: $current_hostname"
						read -p "是否要更改主机名？(y/n): " answer
						if [[ "${answer,,}" == "y" ]]; then
							# 获取新的主机名
							read -p "请输入新的主机名: " new_hostname
							if [ -n "$new_hostname" ]; then
								if [ -f /etc/alpine-release ]; then
									# Alpine
									echo "$new_hostname" > /etc/hostname
									hostname "$new_hostname"
								else
									# 其他系统，如 Debian, Ubuntu, CentOS 等
									hostnamectl set-hostname "$new_hostname"
									sed -i "s/$current_hostname/$new_hostname/g" /etc/hostname
									systemctl restart systemd-hostnamed
								fi
									echo "主机名已更改为: $new_hostname"
							else
								echo "无效的主机名。未更改主机名。"
								exit 1
							fi
						else
							echo "未更改主机名。"
						fi
						;;

					# 切换系统更新源
					19)
						root_use
						# 获取系统信息
						source /etc/os-release

						# 定义 Ubuntu 更新源
						aliyun_ubuntu_source="http://mirrors.aliyun.com/ubuntu/"
						official_ubuntu_source="http://archive.ubuntu.com/ubuntu/"
						initial_ubuntu_source=""

						# 定义 Debian 更新源
						aliyun_debian_source="http://mirrors.aliyun.com/debian/"
						official_debian_source="http://deb.debian.org/debian/"
						initial_debian_source=""

						# 定义 CentOS 更新源
						aliyun_centos_source="http://mirrors.aliyun.com/centos/"
						official_centos_source="http://mirror.centos.org/centos/"
						initial_centos_source=""

						# 获取当前更新源并设置初始源
						case "$ID" in
							ubuntu)
								initial_ubuntu_source=$(grep -E '^deb ' /etc/apt/sources.list | head -n 1 | awk '{print $2}')
								;;

							debian)
								initial_debian_source=$(grep -E '^deb ' /etc/apt/sources.list | head -n 1 | awk '{print $2}')
								;;

							centos)
								initial_centos_source=$(awk -F= '/^baseurl=/ {print $2}' /etc/yum.repos.d/CentOS-Base.repo | head -n 1 | tr -d ' ')
								;;
							*)
								echo "未知系统，无法执行切换源脚本"
								exit 1
								;;
						esac

						# 备份当前源
						backup_sources() {
							case "$ID" in
								ubuntu)
									cp /etc/apt/sources.list /etc/apt/sources.list.bak
									;;

								debian)
									cp /etc/apt/sources.list /etc/apt/sources.list.bak
									;;

								centos)
									if [ ! -f /etc/yum.repos.d/CentOS-Base.repo.bak ]; then
										cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
									else
										echo "备份已存在，无需重复备份"
									fi
									;;

								*)
									echo "未知系统，无法执行备份操作"
									exit 1
									;;
							esac
							echo "已备份当前更新源为 /etc/apt/sources.list.bak 或 /etc/yum.repos.d/CentOS-Base.repo.bak"
						}

						# 还原初始更新源
						restore_initial_source() {
							case "$ID" in
								ubuntu)
									cp /etc/apt/sources.list.bak /etc/apt/sources.list
									;;

								debian)
									cp /etc/apt/sources.list.bak /etc/apt/sources.list
									;;

								centos)
									cp /etc/yum.repos.d/CentOS-Base.repo.bak /etc/yum.repos.d/CentOS-Base.repo
									;;

								*)
									echo "未知系统，无法执行还原操作"
									exit 1
									;;
							esac
							echo "已还原初始更新源"
						}

						# 函数：切换更新源
						switch_source() {
							case "$ID" in
								ubuntu)
									sed -i 's|'"$initial_ubuntu_source"'|'"$1"'|g' /etc/apt/sources.list
									;;

								debian)
									sed -i 's|'"$initial_debian_source"'|'"$1"'|g' /etc/apt/sources.list
									;;

								centos)
									sed -i "s|^baseurl=.*$|baseurl=$1|g" /etc/yum.repos.d/CentOS-Base.repo
									;;

								*)
									echo "未知系统，无法执行切换操作"
									exit 1
									;;
							esac
						}

						# 主菜单
						while true; do
							case "$ID" in
								ubuntu)
									echo "Ubuntu 更新源切换脚本"
									echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
									;;

								debian)
									echo "Debian 更新源切换脚本"
									echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
									;;

								centos)
									echo "CentOS 更新源切换脚本"
									echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
									;;

								*)
									echo "未知系统，无法执行脚本"
									exit 1
									;;
							esac

							echo "1. 切换到阿里云源"
							echo "2. 切换到官方源"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "3. 备份当前更新源"
							echo "4. 还原初始更新源"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "0. 返回上一级"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							read -p "请选择操作: " choice

							case $choice in
								# 切换到阿里云源
								1)
									backup_sources
									case "$ID" in
										ubuntu)
											switch_source $aliyun_ubuntu_source
											;;

										debian)
											switch_source $aliyun_debian_source
											;;

										centos)
											switch_source $aliyun_centos_source
											;;

										*)
											echo "未知系统，无法执行切换操作"
											exit 1
											;;
									esac
									echo -e "${green}已切换到阿里云源${normal}"
									;;

								# 切换到官方源
								2)
									backup_sources
									case "$ID" in
										ubuntu)
											switch_source $official_ubuntu_source
											;;

										debian)
											switch_source $official_debian_source
											;;

										centos)
											switch_source $official_centos_source
											;;

										*)
											echo "未知系统，无法执行切换操作"
											exit 1
											;;
									esac
									echo -e ${green}"已切换到官方源${normal}"
									;;

								# 备份当前更新源
								3)
									backup_sources
									case "$ID" in
										ubuntu)
											switch_source $initial_ubuntu_source
											;;
										debian)
											switch_source $initial_debian_source
											;;
										centos)
											switch_source $initial_centos_source
											;;
										*)
											echo "未知系统，无法执行切换操作"
											exit 1
											;;
									esac
									echo -e "${green}已切换到初始更新源${normal}"
									;;

								# 还原初始更新源
								4)
									restore_initial_source
									;;

								0)
									break
									;;

								*)
									echo "无效的选择，请重新输入"
									;;
							esac
							break_end
						done
						;;

					# 定时任务管理
					20)
						while true; do
							clear
							echo -e "${baizise}${bold}                  定时任务列表                  ${jiacu}"
							crontab -l
							echo ""
							echo -e "${cyan}操作${normal}"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "1. 添加定时任务              2. 删除定时任务              3. 编辑定时任务"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "0. 返回上一级选单"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							read -p "请输入你的选择: " sub_choice

							case $sub_choice in
								# 添加定时任务
								1)
									read -p "请输入新任务的执行命令: " newquest
									echo "------------------------"
									echo "1. 每月任务                 2. 每周任务"
									echo "3. 每天任务                 4. 每小时任务"
									echo "------------------------"
									read -p "请输入你的选择: " dingshi

									case $dingshi in
										1)
											read -p "选择每月的几号执行任务？ (1-30): " day
											(crontab -l ; echo "0 0 $day * * $newquest") | crontab - > /dev/null 2>&1
											;;
										2)
											read -p "选择周几执行任务？ (0-6，0代表星期日): " weekday
											(crontab -l ; echo "0 0 * * $weekday $newquest") | crontab - > /dev/null 2>&1
											;;
										3)
											read -p "选择每天几点执行任务？（小时，0-23）: " hour
											(crontab -l ; echo "0 $hour * * * $newquest") | crontab - > /dev/null 2>&1
											;;
										4)
											read -p "输入每小时的第几分钟执行任务？（分钟，0-60）: " minute
											(crontab -l ; echo "$minute * * * * $newquest") | crontab - > /dev/null 2>&1
											;;
										*)
											break  # 跳出
											;;
									esac
									;;

								# 删除定时任务
								2)
									read -p "请输入需要删除任务的关键字: " kquest
									crontab -l | grep -v "$kquest" | crontab -
									;;

								# 编辑定时任务
								3)
									crontab -e
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

					# 本机 host 解析
					21)
						root_use
						while true; do
							echo -e "${baizise}${bold}                  本机 host 解析列表            ${jiacu}"
							echo ""
							echo "如果你在这里添加解析匹配，将不再使用动态解析了"
							cat /etc/hosts
							echo ""
							echo "操作"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "1. 添加新的解析              2. 删除解析地址"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "0. 返回上一级选单"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							read -p "请输入你的选择: " host_dns

							case $host_dns in
								# 添加新的解析
								1)
									read -p "请输入新的解析记录 格式: 110.25.5.33 kejilion.pro : " addhost
									echo "$addhost" >> /etc/hosts
									;;

								# 删除解析地址
								2)
									read -p "请输入需要删除的解析内容关键字: " delhost
									sed -i "/$delhost/d" /etc/hosts
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

					# fail2banSSH 防御程序
					22)
						root_use
						if docker inspect fail2ban &>/dev/null ; then
							while true; do
								clear
								echo -e "${baizise}${bold}                  SSH 防御程序已启动            ${jiacu}"
								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								echo "1. 查看 SSH 拦截记录"
								echo "2. 日志实时监控"
								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								echo "9. 卸载防御程序"
								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								echo "0. 退出"
								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								read -p "请输入你的选择: " sub_choice

								case $sub_choice in
									# 查看 SSH 拦截记录
									1)
										echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
										f2b_sshd
										echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
										;;

									# 日志实时监控
									2)
										tail -f /path/to/fail2ban/config/log/fail2ban/fail2ban.log
										break
										;;

									# 卸载防御程序
									9)
										docker rm -f fail2ban
										rm -rf /path/to/fail2ban
										echo "Fail2Ban 防御程序已卸载"
										break
										;;

									0)
										break
										;;

									*)
										echo "无效的选择，请重新输入。"
										;;
								esac
								break_end
							done

						elif [ -x "$(command -v fail2ban-client)" ] ; then
							clear
							echo "卸载旧版 fail2ban"
							read -p "确定继续吗？(Y/N): " choice
							case "$choice" in
								[Yy])
									remove fail2ban
									rm -rf /etc/fail2ban
									echo -e "${green}Fail2Ban 防御程序已卸载${normal}"
									;;

								[Nn])
									echo "已取消"
									;;

								*)
									echo "无效的选择，请输入 Y 或 N。"
									;;

							esac

						else

							clear
							echo "fail2ban 是一个 SSH 防止暴力破解工具"
							echo "官网介绍: https://github.com/fail2ban/fail2ban"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							echo "工作原理：研判非法IP恶意高频访问 SSH 端口，自动进行IP封锁"
							echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
							read -p "确定继续吗？(Y/N): " choice

							case "$choice" in
								[Yy])
									clear
									install_docker
									f2b_install_sshd

									cd ~
									f2b_status
									echo -e "${green}Fail2Ban 防御程序已开启${normal}"
									;;

								[Nn])
									echo "已取消"
									;;

								*)
									echo "无效的选择，请输入 Y 或 N。"
									;;
							esac
						fi
						;;

					# 限流自动关机
					23)
						root_use
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						echo -e "${red}${bold}当月流量使用情况，重启服务器流量计算会清零！"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						output_status
						echo "$output"

						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						# 检查是否存在 Limiting_Shut_down.sh 文件
						if [ -f ~/Limiting_Shut_down.sh ]; then
							# 获取 threshold_gb 的值
							threshold_gb=$(grep -oP 'threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
							threshold_tb=$((threshold_gb / 1024))
							echo -e "当前设置的限流阈值为 ${yellow}${threshold_gb}${normal} GB / ${yellow}${threshold_tb}${normal} TB"
						else
							echo -e "${yellow}前未启用限流关机功能${normal}"
						fi

						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"

						echo ""
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						echo "系统每分钟会检测实际流量是否到达阈值，到达后会自动关闭服务器！每月1日重置流量重启服务器。"
						echo "1. 开启限流关机功能"
						echo "2. 停用限流关机功能"
						echo "0. 退出"
	#            		read -p "1. 开启限流关机功能    2. 停用限流关机功能    0. 退出  : " Limiting
						read -p "请输入你的选择: " Limiting

						case "$Limiting" in
							# 开启限流关机功能
							1)
								# 输入新的虚拟内存大小
								echo "如果实际服务器就100G流量，可设置阈值为95G，提前关机，以免出现流量误差或溢出."
								read -p "请输入流量阈值（单位为GB）: " threshold_gb
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

							# 停用限流关机功能
							2)
								crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
								crontab -l | grep -v 'reboot' | crontab -
								rm ~/Limiting_Shut_down.sh
								echo "已关闭限流关机功能"
							;;

							0)
								echo "已取消"
								;;

							*)
								echo "无效的选择，请输入 Y 或 N。"
								;;
						esac
						;;

					# ROOT 私钥登录模式
					24)
						root_use
						echo -e "${cyan}ROOT私钥登录模式${normal}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						echo "将会生成密钥对，更安全的方式SSH登录"
						read -p "确定继续吗？(Y/N): " choice

						case "$choice" in
							[Yy])
								clear
								add_sshkey
								;;

							[Nn])
								echo "已取消"
								;;

							*)
								echo "无效的选择，请输入 Y 或 N。"
								;;
						esac

						;;

					# 留言板
					31)
						clear
						install sshpass

						remote_ip="66.42.61.110"
						remote_user="liaotian123"
						remote_file="/home/liaotian123/liaotian.txt"
						password="kejilionYYDS"  # 替换为您的密码

						clear
						echo "leon 留言板"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						# 显示已有的留言内容
						sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${remote_user}@${remote_ip}" "cat '${remote_file}'"
						echo ""
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"

						# 判断是否要留言
						read -p "是否要留言？(y/n): " leave_message

						if [ "$leave_message" == "y" ] || [ "$leave_message" == "Y" ]; then
							# 输入新的留言内容
							read -p "输入你的昵称: " nicheng
							read -p "输入你的聊天内容: " neirong

							# 添加新留言到远程文件
							sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${remote_user}@${remote_ip}" "echo -e '${nicheng}: ${neirong}' >> '${remote_file}'"
							echo "已添加留言: "
							echo "${nicheng}: ${neirong}"
							echo ""
						else
							echo "您选择了不留言。"
						fi

						echo "留言板操作完成。"

						;;

					# 一条龙系统调优
					66)
						root_use
						echo -e "${cyan}一条龙系统调优${normal}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						echo "将对以下内容进行操作与优化"
						echo "1. 更新系统到最新"
						echo "2. 清理系统垃圾文件"
						echo -e "3. 设置虚拟内存${yellow}1G${normal}"
						echo -e "4. 设置SSH端口号为${yellow}5522${normal}"
						echo -e "5. 开放所有端口"
						echo -e "6. 开启${yellow}BBR${normal}加速"
						echo -e "7. 设置时区到${yellow}上海${normal}"
						echo -e "8. 优化DNS地址到${yellow}1111 8888${normal}"
						echo -e "9. 安装常用工具${yellow}docker wget sudo tar unzip socat btop${normal}"
						echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						read -p "确定一键保养吗？(Y/N): " choice

						case "$choice" in
							[Yy])
								clear
								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								linux_update
								echo -e "[${green}OK${normal}] 1/9. 更新系统到最新"

								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								linux_clean
								echo -e "[${green}OK${normal}] 2/9. 清理系统垃圾文件"

								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								new_swap=1024
								add_swap
								echo -e "[${green}OK${normal}] 3/9. 设置虚拟内存${huang}1G${normal}"

								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								new_port=5522
								new_ssh_port
								echo -e "[${green}OK${normal}] 4/9. 设置 SSH 端口号为 ${huang}5522${normal}"
								echo -e "[${green}OK${normal}] 5/9. 开放所有端口"

								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								bbr_on
								echo -e "[${green}OK${normal}] 6/9. 开启${huang} BBR ${normal}加速"

								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								set_timedate Asia/Shanghai
								echo -e "[${green}OK${normal}] 7/9. 设置时区到${huang}上海${normal}"

								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								dns1_ipv4="1.1.1.1"
								dns2_ipv4="8.8.8.8"
								dns1_ipv6="2606:4700:4700::1111"
								dns2_ipv6="2001:4860:4860::8888"
								set_dns
								echo -e "[${green}OK${normal}] 8/9. 优化 DNS 地址到${huang}1111 8888${normal}"

								echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
								install_add_docker
								install wget sudo tar unzip socat btop
								echo -e "[${green}OK${normal}] 9/9. 安装常用工具 ${huang}docker wget sudo tar unzip socat btop${normal}"
								echo -e "${green}一条龙系统调优已完成${normal}"
								;;

							[Nn])
								echo "已取消"
								;;

							*)
								echo "无效的选择，请输入 Y 或 N。"
								;;
						esac
						;;

					# 重启服务器
					99)
						clear
						server_reboot
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

		# VPS 集群控制
  		14)
			clear
			while true; do
			clear
			echo -e "${baizise}${bold}                  ▶ VPS 集群控制                ${jiacu}"
			echo "你可以远程操控多台 VPS 一起执行任务（仅支持 Ubuntu/Debian）"
			echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
			echo "1. 安装集群环境"
			echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
			echo "2. 集群控制中心"
			echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
			echo "7. 备份集群环境"
			echo "8. 还原集群环境"
			echo "9. 卸载集群环境"
			echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
			echo "0. 返回主菜单"
			echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
			read -p "请输入你的选择: " sub_choice

      		case $sub_choice in
      			# 安装集群环境
          		1)
            		clear
					install python3 python3-paramiko speedtest-cli lrzsz
					mkdir cluster && cd cluster
					touch servers.py

            		cat > ./servers.py << EOF
servers = [

]
EOF

              		;;

            	# 集群控制中心
          		2)

              		while true; do
						clear
						echo -e "${baizise}${bold}                  集群服务器列表                ${jiacu}"
						cat ~/cluster/servers.py

                  		echo ""
                  		echo -e "${cyan}操作${normal}"
                        echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
                        echo "1. 添加服务器                2. 删除服务器             3. 编辑服务器"
                        echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
                        echo "11. 安装 Leon 脚本           12. 更新系统              13. 清理系统"
                        echo "14. 安装 docker              15. 安装 BBR3             16. 设置 1G 虚拟内存"
                        echo "17. 设置时区到上海           18. 开放所有端口"
                        echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
                        echo "51. 自定义指令"
                        echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
                        echo "0. 返回上一级选单"
                        echo -e "${cyan}${bold}------------------------------------------------${jiacu}"
						read -p "请输入你的选择: " sub_choice

                  		case $sub_choice in
                  			# 添加服务器
							1)
                          		read -p "服务器名称: " server_name
								read -p "服务器IP: " server_ip
								read -p "服务器端口（22）: " server_port
								server_port=${server_port:-22}
								read -p "服务器用户名（root）: " server_username
								server_username=${server_username:-root}
								read -p "服务器用户密码: " server_password

                          		sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py
                          		;;

                        	# 删除服务器
                      		2)
						  		read -p "请输入需要删除的关键字: " rmserver
						  		sed -i "/$rmserver/d" ~/cluster/servers.py
						  		;;

							# 编辑服务器
                      		3)
							  	install nano
							  	nano ~/cluster/servers.py
							  	;;

							# 安装 Leon 脚本
                      		11)
#                      			ToDo 需要新增脚本
							  	py_task=install_kejilion.py
							  	cluster_python3
								;;

							# 更新系统
                      		12)
								py_task=update.py
							  	cluster_python3
							  	;;

							# 清理系统
                      		13)
							  	py_task=clean.py
							  	cluster_python3
							  	;;

							# 安装 docker
                      		14)
							  	py_task=install_docker.py
							  	cluster_python3
							  	;;

							# 安装 BBR3
                      		15)
							  	py_task=install_bbr3.py
							  	cluster_python3
							  	;;

							# 设置 1G 虚拟内存
                      		16)
                          		py_task=swap1024.py
                          		cluster_python3
                          		;;

                        	# 设置时区到上海
                      		17)
                          		py_task=time_shanghai.py
                          		cluster_python3
                          		;;

                        	# 开放所有端口
                      		18)
                          		py_task=firewall_close.py
                          		cluster_python3
                         		;;

                       		# 自定义指令
                      		51)

                          		read -p "请输入批量执行的命令: " mingling
                          		py_task=custom_tasks.py
                          		cd ~/cluster/
#                          		ToDo 需要新增脚本
                          		curl -sS -O https://raw.githubusercontent.com/kejilion/python-for-vps/main/cluster/$py_task
							  	sed -i "s#Customtasks#$mingling#g" ~/cluster/$py_task
							  	python3 ~/cluster/$py_task
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

            	# 备份集群环境
          		7)
					clear
					echo "将下载服务器列表数据，按任意键下载！"
					read -n 1 -s -r -p ""
					sz -y ~/cluster/servers.py
              		;;

				# 还原集群环境
			  	8)
					clear
					echo "请上传您的servers.py，按任意键开始上传！"
					read -n 1 -s -r -p ""
					cd ~/cluster/
					rz -y
              		;;

				# 卸载集群环境
          		9)
            		clear
		            read -p "请先备份环境，确定要卸载集群控制环境吗？(Y/N): " choice
            		case "$choice" in
              			[Yy])
                			remove python3-paramiko speedtest-cli lrzsz
                			rm -rf ~/cluster/
                			;;

              			[Nn])
                			echo "已取消"
                			;;

              			*)
                			echo "无效的选择，请输入 Y 或 N。"
                			;;
            		esac

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

		# 幻兽帕鲁开服脚本
		p)
			cd ~
			curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/palworld.sh && chmod +x palworld.sh && ./palworld.sh
			exit
			;;

		# 脚本更新
		00)
			cd ~
			clear
			echo -e "${cyan}更新日志${normal}"
			echo "------------------------"
			echo "全部日志: https://raw.githubusercontent.com/oliver556/sh/main/leon_sh_log.txt"
			echo "------------------------"
			curl -s https://raw.githubusercontent.com/oliver556/sh/main/leon_sh_log.txt | tail -n 35
			echo ""
			echo ""
			sh_v_new=$(curl -s https://raw.githubusercontent.com/oliver556/sh/main/leon.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

			if [ "$sh_v" = "$sh_v_new" ]; then
				echo -e "${green}你已经是最新版本！${yellow}v$sh_v${normal}"
			else
				echo "发现新版本！"
				echo -e "当前版本 v$sh_v        最新版本 ${yellow}v$sh_v_new${normal}"
				echo "------------------------"
				read -p "确定更新脚本吗？(Y/N): " choice
				case "$choice" in
					[Yy])
						clear
						curl -sS -O https://raw.githubusercontent.com/oliver556/sh/main/leon.sh && chmod +x leon.sh
						echo -e "${green}脚本已更新到最新版本！${yellow}v$sh_v_new${normal}"
						break_end
						leon
						;;
					[Nn])
						echo "已取消"
						;;
					*)
						;;
				esac
			fi

    	;;

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
