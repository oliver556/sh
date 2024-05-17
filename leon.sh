#!/bin/bash

# 脚本版本
sh_v="1.0.8"


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

			printf("总接收: %.2f %s\n总发送: %.2f %s\n", rx_total, rx_units, tx_total, tx_units);
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

# 函数: 判断服务器系统类型
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

# 函数: speedtest 测速工具
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
				echo "正在运行 speedtest 进行测试"
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
		curl -fsSL https://get.docker.com | sh && ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin
		systemctl start docker
		systemctl enable docker
	fi

	sleep 2
}

# 函数: 是否以 root 用户身份运行
root_use() {
	clear
	[ "$EUID" -ne 0 ] && echo -e "${red}请注意，该功能需要 root 用户 才能运行！${normal}" && break_end && leon
}

# 函数: 设置允许 ROOT 用户通过 SSH 登录，并设置 ROOT 用户的密码
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
	# 函数: 根据系统中安装的包管理器来使用适当的命令来重启 SSH 服务
	restart_ssh
	# 显示消息，表示 ROOT 登录设置完成
	echo -e "${green}ROOT登录设置完毕！${normal}"
	# 函数: 询问用户是否要重启服务器
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
		echo "无法找到SSH服务启动脚本，无法重启SSH服务!"
		return 1
	fi
}

# 函数: 询问用户是否要重启服务器
server_reboot() {
	# 输入是否要重启服务器，用户可以输入 "Y" 或 "N" 来回答
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

# 函数: 修改 SSH 连接端口
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

# 函数: 配置 DNS 解析器
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

	echo -e "${green}DNS 地址已更新${normal}"
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

	# 创建新的 swap 文件:
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

	echo -e "虚拟内存大小已调整为${yellow}${new_swap}${normal} MB"
}

# 函数: 获取当前系统时区
current_timezone() {
	if grep -q 'Alpine' /etc/issue; then
	 :
	else
	 timedatectl show --property=Timezone --value
	fi
}

# 函数: 重启服务器
restart_the_server() {
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
	if ! command -v docker &>/dev/null || ! command -v docker-compose &>/dev/null; then
		install_add_docker
	else
		echo "Docker环境已经安装"
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
	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
  	     -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
    	   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
      	 -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	echo -e "${grey}ROOT私钥登录已开启，已关闭ROOT密码登录，重连将会生效${normal}"
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

# 函数: 安装依赖（wget socat unzip tar）
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
	curl -O https://raw.githubusercontent.com/kejilion/sh/main/auto_cert_renewal.sh
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

# 函数: 获取当前环境中 Nginx、MySQL、PHP 和 Redis 的版本信息
ldnmp_v() {
	# 获取 nginx 版本
	nginx_version=$(docker exec nginx nginx -v 2>&1)
	nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+" || echo "未安装")
	echo -n -e "nginx : ${yellow}v$nginx_version${normal}"

	# 获取 mysql 版本
  dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml 2>/dev/null | tr -d '[:space:]' || echo "未安装")
  mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1) && mysql_version="v$mysql_version" || mysql_version="未安装"
  echo -n -e "            mysql : ${yellow}$mysql_version${normal}"



	# 获取 php 版本
	php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+"  || echo "未安装")
	echo -n -e "            php : ${yellow}v$php_version${normal}"

	# 获取 redis 版本
	redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+"  || echo "未安装")
	echo -e "            redis : ${yellow}v$redis_version${normal}"

	echo "------------------------"
	echo ""
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
		echo "nginx 环境已安装，开始部署 $web_name"
	else
		echo -e "${yellow}nginx 未安装，请先安装 nginx 环境，再部署网站${normal}"
	break_end
	leon

	fi
}

# 函数: 获取 IP，及收集用户输入要解析的域名
add_yuming() {
	ip_address
	echo -e "先将域名解析到本机 IP: ${yellow}$ipv4_address  $ipv6_address${normal}"
	read -p "请输入你解析的域名: " yuming
}

# 函数: 输出建站 IP
nginx_web_on() {
	clear
	echo "您的 $web_name 搭建好了！"
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

#=======================================================================================================================================

while true; do
	clear

#	echo -e "${green}# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #"
#	echo "# _    ____  ____ _  _                                        #"
#	echo "# |    |___  |  | |\ |                                        #"
#	echo -e "# |___ |___  |__| | \|    ${yellow}v$sh_v${normal}                              ${green}#${normal}"
#	echo -e "${green}#                                                             #${normal}"
#	echo -e "${green}# Leon 一键脚本工具（支持 Ubuntu/Debian/CentOS/Alpine 系统）${normal}  ${green}#${normal}"
#	echo -e "${green}# 输入${yellow} n ${green}可快速启动此脚本 ${normal}                                    ${green}#${normal}"
#	echo -e "${green}# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #${normal}"

	echo -e "${green}${bold}# ==========================================================="
	echo -e "${green}# _    ____  ____ _  _ "
	echo -e "${green}# |    |___  |  | |\ | "
	echo -e "${green}# |___ |___  |__| | \|   ${cyan}v$sh_v${normal}"
	echo -e "${green}${bold}# "
	echo -e "${green}# Leon 一键脚本工具（支持 Ubuntu/Debian/CentOS/Alpine 系统）${normal}"
	echo -e "${green}${bold}# 输入${yellow} n ${green}可快速启动此脚本 ${normal}"
	echo -e "${green}${bold}# ===========================================================${jiacu}"
	echo ""

#	echo -e "${green}========================================================= "
#	echo "_    ____  ____ _  _ "
#	echo "|    |___  |  | |\ | "
#	echo -e "|___ |___  |__| | \|   ${yellow}v$sh_v${normal}"
#	echo ""
#	echo -e "${green}Leon 一键脚本工具（支持 Ubuntu/Debian/CentOS/Alpine 系统）${normal}"
#	echo -e "${green}输入${yellow} n ${green}可快速启动此脚本 ${normal}"
#	echo -e "${green}=========================================================${normal}"
#	echo ""

	echo "1. 系统信息查询"
	echo "2. 系统更新"
	echo "3. 系统清理"
	echo "4. 常用工具 ▶"
	echo "5. BBR 管理 ▶"
	echo "6. Docker 管理 ▶ "
	echo "8. 测试脚本合集 ▶ "
	echo "10. LDNMP 建站 ▶ "
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
			# 执行函数: 获取 IPv4 和 IPv6 地址
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

			# 执行函数:
			output_status

			echo ""
			# echo -e "${cyan}{normal}"
			echo -e "${baizise}${bold}    			系统信息查询			    ${jiacu}"
			echo "------------------------"
			echo "主机名: $host_name"
			echo "运营商: $isp_info"
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
						echo "工具已安装，使用方法如下: "
						curl --help
						;;

					# wget 下载工具
					2)
						clear
						install wget
						clear
						echo "工具已安装，使用方法如下: "
						wget --help
						;;

					# sudo 超级管理权限工具
					3)
						clear
						install sudo
						clear
						echo "工具已安装，使用方法如下: "
						sudo --help
						;;

					# socat 通信连接工具 （申请域名证书必备）
					4)
						clear
						install socat
						clear
						echo "工具已安装，使用方法如下: "
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
						echo "工具已安装，使用方法如下: "
						unzip
						;;

					# tar GZ压缩解压工具
					8)
						clear
						install tar
						clear
						echo "工具已安装，使用方法如下: "
						tar --help
						;;

					# tmux 多路后台运行工具
					9)
						clear
						install tmux
						clear
						echo "工具已安装，使用方法如下: "
						tmux --help
						;;

					# ffmpeg 视频编码直播推流工具
					10)
						clear
						install ffmpeg
						clear
						echo "工具已安装，使用方法如下: "
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
				echo -e "${cyan}▶ Docker 管理器${normal}"
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
						echo -e "${cyan}Docker 版本${normal}"
						echo "------------------------"
						docker --version
						docker-compose --version
						echo ""
						echo -e "${cyan}Docker 镜像列表${normal}"
						echo "------------------------"
						docker image ls
						echo ""
						echo -e "${cyan}Docker 容器列表${normal}"
						echo "------------------------"
						docker ps -a
						echo ""
						echo -e "${cyan}Docker 卷列表${normal}"
						echo "------------------------"
						docker volume ls
						echo ""
						echo -e "${cyan}Docker 网络列表${normal}"
						echo "------------------------"
						docker network ls
						echo ""
						;;

					# Docker 容器管理
					# ToDo docker 容器管理未完成
					# 需求: 查看（日志、网络）、创建、更新、重启、停止、删除，
					3)
						while true; do
							clear
							echo -e "${cyan}Docker 容器列表${normal}"
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
									read -p "请输入创建命令: " docker_name
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
				echo "----网络测试-----------"
				echo "11. speedtest 网络带宽测速"
				echo ""
				echo "----综合性测试-----------"
				echo "41. Disk Test 硬盘&系统综合测试"
				echo "42. bench 性能测试"
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

					# speedtest Server network 网络测速工具
					11)
						clear
						speed_test_tool
						;;

					# 杜甫性能测试
					41)
						clear
            curl -sS -O https://raw.githubusercontent.com/oliver556/sh/main/A.sh && chmod +x A.sh && ./A.sh
						;;

					# bench 性能测试
					42)
						clear
						curl -Lso- bench.sh | bash
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

		# LDNMP 建站
		10)
			while true; do
				clear
				echo -e "${cyan}LDNMP 建站${normal}"
				echo  "------------------------"
				echo  "1. 安装 LDNMP 环境"
				echo  "------------------------"
				echo  "21. 仅安装 nginx"
				echo  "22. 站点重定向"
				echo  "23. 站点反向代理"
				echo  "24. 自定义静态站点"
				echo  "------------------------"
				echo  "31. 站点数据管理"
				echo  "------------------------"
				echo  "0. 返回主菜单"
				echo  "------------------------"

				read -p "请输入你的选择: " sub_choice

				case $sub_choice in
					# 仅安装 nginx
					21)
						root_use
						# 检查端口
						check_port
						# 安装依赖（wget socat unzip tar）
						install_dependency
						# 安装 docker
						install_docker
						# 安装 certbot 工具
						install_certbot

						cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/redis web/log/nginx

						wget -O /home/web/nginx.conf https://raw.githubusercontent.com/oliver556/sh/main/nginx/nginx10.conf
						wget -O /home/web/conf.d/default.conf https://raw.githubusercontent.com/oliver556/sh/main/nginx/default10.conf
						# 创建自签名的 SSL 证书
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
						web_name="站点重定向"
						# Nginx 环境检查
						nginx_install_status
						# 公网 IP 查询
						ip_address
						# 获取 IP，及收集用户输入要解析的域名
						add_yuming
						read -p "请输入跳转域名: " reverseproxy

						# 获取 SSL/TLS 证书
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
						web_name="站点反向代理"
						# Nginx 环境检查
						nginx_install_status
						# 公网 IP 查询
						ip_address
						# 获取 IP，及收集用户输入要解析的域名
						add_yuming
						read -p "请输入你的反代 IP: " reverseproxy
						read -p "请输入你的反代端口: " port

						# 获取 SSL/TLS 证书
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
						web_name="静态站点"
						# Nginx 环境检查
						nginx_install_status
						# 获取 IP，及收集用户输入要解析的域名
						add_yuming
						# 获取 SSL/TLS 证书
						install_ssltls

						wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/oliver556/sh/main/nginx/html.conf
						sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

						cd /home/web/html
						mkdir $yuming
						cd $yuming

						clear
						echo "-------------"
						echo -e "目前只允许上传 zip 格式的源码包，请将源码包放到 ${yellow}/home/web/html/${yuming}目录下${normal}"
						read -p "也可以输入下载链接，远程下载源码包，直接回车将跳过远程下载:  " url_download

						if [ -n "$url_download" ]; then
							wget "$url_download"
						fi

						unzip $(ls -t *.zip | head -n 1)
						rm -f $(ls -t *.zip | head -n 1)

						clear

						echo -e "${cyan}index.html所在路径${normal}"
						echo "-------------"
						find "$(realpath .)" -name "index.html" -print

						read -p "请输入 index.html 的路径，类似（/home/web/html/$yuming/wordpress/）:  " index_lujing

						sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
						sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

						docker exec nginx chmod -R 777 /var/www/html
						docker restart nginx

						# 输出建站 IP
						nginx_web_on
						# 检查 docker、证书申请 状态
						nginx_status
						;;

					# 站点数据管理
					31)
						root_use
						while true;do
							clear
							echo -e "${cyan}LDNMP 环境${normal}"
							echo "------------------------"
							# 获取当前环境中 Nginx、MySQL、PHP 和 Redis 的版本信息
							ldnmp_v

							echo "站点信息                      证书到期时间"
							echo "------------------------"
							for cert_file in /home/web/certs/*_cert.pem; do
								domain=$(basename "$cert_file" | sed 's/_cert.pem//')
								if [ -n "$domain" ]; then
									expire_date=$(openssl x509 -noout -enddate -in "$cert_file" | awk -F'=' '{print $2}')
									formatted_date=$(date -d "$expire_date" '+%Y-%m-%d')
									printf "%-30s%s\n" "$domain" "$formatted_date"
								fi
							done

							echo "------------------------"
							echo ""
							echo "数据库信息"
							echo "------------------------"
							dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
							docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2> /dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys"

							echo "------------------------"
							echo ""
							echo "站点目录"
							echo "------------------------"
							echo -e "数据 ${grey}/home/web/html${normal}     证书 ${grey}/home/web/certs${normal}     配置 ${grey}/home/web/conf.d${normal}"
							echo "------------------------"
							echo ""
							echo "操作"
							echo "------------------------"
							echo -e "1. 申请/更新域名证书               ${grey}2. 更换站点域名${normal}"
							echo "3. 清理站点缓存                    4. 查看站点分析报告"
							echo "5. 查看全局配置                    6. 查看站点配置"
							echo "------------------------"
							echo "7. 删除指定站点                    8. 删除指定数据库"
							echo "------------------------"
							echo "0. 返回上一级选单"
							echo "------------------------"
							read -p "请输入你的选择: " sub_choice

							case $sub_choice in
								# 申请/更新域名证书
								1)
									read -p "请输入你的域名: " yuming
									# 获取 SSL/TLS 证书
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
				echo -e "${cyan}▶ 面板工具${normal}"
				echo "------------------------"
				echo "7. 哪吒探针 VPS 监控面板"
				echo "------------------------"
				echo "0. 返回主菜单"
				echo "------------------------"
				read -p "请输入你的选择: " sub_choice

				case $sub_choice in
					# 哪吒探针 VPS 监控面板
					7)
						curl -L https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh  -o nezha.sh && chmod +x nezha.sh
						./nezha.sh
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
				echo -e "${cyan}▶ 系统工具${normal}"
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
								echo -e "${green}开始安装最新版 Python3...${normal}"
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
						open_all_ports
						remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
						echo -e "${green}端口已全部开放${normal}"
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
						echo -e "${cyan}当前 DNS 地址${normal}"
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
							echo -e "${cyan}用户列表${normal}"
							echo "----------------------------------------------------------------------------"
							printf "%-24s %-34s %-20s %-10s\n" "用户名" "用户权限" "用户组" "sudo 权限"
							while IFS=: read -r username _ userid groupid _ _ homedir shell; do
								groups=$(groups "$username" | cut -d : -f 2)
								sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
								printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
								done < /etc/passwd

							echo ""
							echo -e "${cyan}账户操作${normal}"
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

								echo -e "${green}操作已完成。${normal}"
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

								echo -e "${green}操作已完成。${normal}"
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

						echo -e "${cyan}随机用户名${normal}"
						echo "------------------------"
						for i in {1..5}; do
								username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
								echo "随机用户名 $i: $username"
						done

						echo ""
						echo -e "${cyan}随机姓名${normal}"
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
						echo -e "${cyan}随机 UUID${normal}"
						echo "------------------------"
						for i in {1..5}; do
							uuid=$(cat /proc/sys/kernel/random/uuid)
							echo "随机UUID $i: $uuid"
						done

            echo ""
            echo -e "${cyan}16位随机密码${normal}"
            echo "------------------------"
            for i in {1..5}; do
                password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
                echo "随机密码 $i: $password"
            done

            echo ""
            echo -e "${cyan}32位随机密码${normal}"
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
							echo -e "${cyan}系统时间信息${normal}"

							# 获取当前系统时区
							timezone=$(current_timezone)

							# 获取当前系统时间
							current_time=$(date +"%Y-%m-%d %H:%M:%S")

							# 显示时区和时间
							echo "当前系统时区: $timezone"
							echo "当前系统时间: $current_time"

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
						root_use

						# 判断是否安装了 linux-xanmod 包
						if dpkg -l | grep -q 'linux-xanmod'; then
							while true; do

								# 获取当前系统的内核版本信息
								kernel_version=$(uname -r)
								echo "您已安装 xanmod 的 BBRv3 内核"
								echo "当前内核版本: $kernel_version"

								echo ""
								echo "内核管理"
								echo "------------------------"
								echo "1. 更新BBRv3内核              2. 卸载BBRv3内核"
								echo "------------------------"
								echo "0. 返回上一级选单"
								echo "------------------------"
								read -p "请输入你的选择: " sub_choice

								case $sub_choice in
									1)
										apt purge -y 'linux-*xanmod1*'

										# 更新 grub 引导加载程序的配置文件
										update-grub

										wget -qO - https://raw.githubusercontent.com/oliver556/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

										# 步骤3: 添加存储库
										echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

										version=$(wget -q https://raw.githubusercontent.com/oliver556/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

										apt update -y
										apt install -y linux-xanmod-x64v$version

										echo "XanMod内核已更新。重启后生效"
										rm -f /etc/apt/sources.list.d/xanmod-release.list
										rm -f check_x86-64_psabi.sh*

										server_reboot
										;;

									2)
										apt purge -y 'linux-*xanmod1*'
										update-grub
										echo "XanMod 内核已卸载。重启后生效"
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
							echo "------------------------------------------------"
							echo "仅支持 Debian/Ubuntu 仅支持 x86_64 架构"
							echo "VPS 是 512M内 存的，请提前添加 1G 虚拟内存，防止因内存不足失联！"
							echo "------------------------------------------------"
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

									# 步骤3: 添加存储库
									echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

									version=$(wget -q https://raw.githubusercontent.com/oliver556/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

									apt update -y
									apt install -y linux-xanmod-x64v$version

									# 步骤5: 启用 BBR3
									cat > /etc/sysctl.conf << EOF
net.core.default_qdisc=fq_pie
net.ipv4.tcp_congestion_control=bbr
EOF
									sysctl -p
									echo "XanMod 内核安装并 BBR3 启用成功。重启后生效"
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

						# 判断是否安装了名为 iptables-persistent 的软件包
						if dpkg -l | grep -q iptables-persistent; then
							while true; do
								echo "防火墙已安装"
								echo "------------------------"
								iptables -L INPUT

								echo ""
								echo "防火墙管理"
								echo "------------------------"
								echo "1. 开放指定端口              2. 关闭指定端口"
								echo "3. 开放所有端口              4. 关闭所有端口"
								echo "------------------------"
								echo "5. IP 白名单                  6. IP 黑名单"
								echo "7. 清除指定 IP"
								echo "------------------------"
								echo "9. 卸载防火墙"
								echo "------------------------"
								echo "0. 返回上一级选单"
								echo "------------------------"
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
										# 从 SSH 配置文件中找到定义的端口号
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

									# IP黑名单
									6)
										read -p "请输入封锁的IP: " c_ip
										sed -i "/COMMIT/i -A INPUT -s $c_ip -j DROP" /etc/iptables/rules.v4
										iptables-restore < /etc/iptables/rules.v4
										;;

									# 清除指定IP
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
							echo "------------------------------------------------"
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
									# 开放所有端口
									open_all_ports
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

	          # 函数: 备份当前源
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

							echo -e "${green}已备份当前更新源为 /etc/apt/sources.list.bak 或 /etc/yum.repos.d/CentOS-Base.repo.bak${normal}"
						}

					 	# 函数: 还原初始更新源
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
							echo -e "${green}已还原初始更新源${normal}"
						}

						# 函数: 切换更新源
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
									echo "------------------------"
									;;

								debian)
									echo "Debian 更新源切换脚本"
									echo "------------------------"
									;;

								centos)
									echo "CentOS 更新源切换脚本"
									echo "------------------------"
									;;

								*)
									echo "未知系统，无法执行脚本"
									exit 1
									;;
              esac

              echo "1. 切换到阿里云源"
							echo "2. 切换到官方源"
							echo "------------------------"
							echo "3. 备份当前更新源"
							echo "4. 还原初始更新源"
							echo "------------------------"
							echo "0. 返回上一级"
							echo "------------------------"
							read -p "请选择操作: " choice

							case $choice in
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
								echo -e "${green}已切换到官方源${normal}"
								;;

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
							echo "定时任务列表"
							crontab -l
							echo ""
							echo "操作"
							echo "------------------------"
							echo "1. 添加定时任务              2. 删除定时任务"
							echo "------------------------"
							echo "0. 返回上一级选单"
							echo "------------------------"
							read -p "请输入你的选择: " sub_choice

							case $sub_choice in
								1)
									read -p "请输入新任务的执行命令: " newquest
									echo "------------------------"
									echo "1. 每周任务                 2. 每天任务"
									read -p "请输入你的选择: " dingshi

									case $dingshi in
										1)
											read -p "选择周几执行任务？ (0-6，0代表星期日): " weekday
											(crontab -l ; echo "0 0 * * $weekday $newquest") | crontab - > /dev/null 2>&1
											;;

										2)
											read -p "选择每天几点执行任务？（小时，0-23）: " hour
											(crontab -l ; echo "0 $hour * * * $newquest") | crontab - > /dev/null 2>&1
											;;

										*)
											break  # 跳出
											;;
									esac
									;;

								2)
									read -p "请输入需要删除任务的关键字: " kquest
									crontab -l | grep -v "$kquest" | crontab -
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
							echo "本机 host 解析列表"
							echo "如果你在这里添加解析匹配，将不再使用动态解析了"
							cat /etc/hosts
							echo ""
							echo "操作"
							echo "------------------------"
							echo "1. 添加新的解析              2. 删除解析地址"
							echo "------------------------"
							echo "0. 返回上一级选单"
							echo "------------------------"
							read -p "请输入你的选择: " host_dns

							case $host_dns in
								1)
									read -p "请输入新的解析记录 格式: 142.251.42.238 google.com : " addhost
									echo "$addhost" >> /etc/hosts
									;;

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
								echo "SSH 防御程序已启动"
								echo "------------------------"
								echo "1. 查看 SSH 拦截记录"
								echo "2. 日志实时监控"
								echo "------------------------"
								echo "9. 卸载防御程序"
								echo "------------------------"
								echo "0. 退出"
								echo "------------------------"
								read -p "请输入你的选择: " sub_choice
								case $sub_choice in
									1)
										echo "------------------------"
										f2b_sshd
										echo "------------------------"
										;;

									2)
										tail -f /path/to/fail2ban/config/log/fail2ban/fail2ban.log
										break
										;;

									9)
										docker rm -f fail2ban
										rm -rf /path/to/fail2ban
										echo "Fail2Ban防御程序已卸载"

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
									echo "Fail2Ban 防御程序已卸载"
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
							echo "------------------------------------------------"
							echo "工作原理: 研判非法 IP 恶意高频访问 SSH 端口，自动进行 IP 封锁"
							echo "------------------------------------------------"
							read -p "确定继续吗？(Y/N): " choice

							case "$choice" in
								[Yy])
									clear
									install_docker
									f2b_install_sshd

									cd ~
									f2b_status
									echo "Fail2Ban防御程序已开启"
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

						echo -e "${cyan}当月流量使用情况，重启服务器流量计算会清零！"
						output_status
						echo "$output"

						# 检查是否存在 Limiting_Shut_down.sh 文件
						if [ -f ~/Limiting_Shut_down.sh ]; then
							# 获取 threshold_gb 的值
							threshold_gb=$(grep -oP 'threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
							threshold_tb=$((threshold_gb / 1024))
							echo -e "当前设置的限流阈值为 ${yellow}${threshold_gb}${normal} GB / ${yellow}${threshold_tb}${normal} TB"
            else
							echo -e "${grey}当前未启用限流关机功能${normal}"
            fi

            echo ""
						echo "------------------------------------------------"
						echo "系统每分钟会检测实际流量是否到达阈值，到达后会自动关闭服务器！每月1日重置流量重启服务器。"
						read -p "1. 开启限流关机功能    2. 停用限流关机功能    0. 退出  : " Limiting

						case "$Limiting" in
							1)
								# 输入新的虚拟内存大小
								echo "如果实际服务器就 100G 流量，可设置阈值为 95G，提前关机，以免出现流量误差或溢出"
								read -p "请输入流量阈值（单位为: GB）: " threshold_gb
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
						root_use

						echo -e "${cyan}ROOT私钥登录模式${normal}"
						echo "------------------------------------------------"
						echo "将会生成密钥对，更安全的方式 SSH 登录"
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
