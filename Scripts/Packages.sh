#!/bin/bash

#安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local REPO_NAME=$(echo $PKG_REPO | cut -d '/' -f 2)

	find ./ ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -exec rm -rf {} +

	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"

	if [[ $PKG_SPECIAL == "pkg" ]]; then
		find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ \;
		rm -rf ./$REPO_NAME/
	elif [[ $PKG_SPECIAL == "name" ]]; then
		mv -f $REPO_NAME $PKG_NAME
	fi
}

#UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg/name，可选，pkg为从大杂烩中单独提取包名插件；name为重命名为包名"
UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-24.10"

#科学插件
UPDATE_PACKAGE "luci-app-ssr-plus" "fw876/helloworld" "master"   #ssr plus
UPDATE_PACKAGE "luci-app-homeproxy" "VIKINGYFY/homeproxy" "main"  #homeproxy
UPDATE_PACKAGE "passwall-packages" "xiaorouji/openwrt-passwall-packages" "main"  #passwall组件
UPDATE_PACKAGE "luci-app-passwall" "xiaorouji/openwrt-passwall" "main" "pkg"   #passwall
#UPDATE_PACKAGE "luci-app-passwall" "xiaorouji/openwrt-passwall" "luci-smartdns-dev" "pkg"
UPDATE_PACKAGE "luci-app-passwall2" "xiaorouji/openwrt-passwall2" "main"    #passwall2
UPDATE_PACKAGE "nekoclash" "Thaolga/luci-app-nekoclash" "main"  #nekoclash
UPDATE_PACKAGE "luci-app-mihomo" "morytyann/OpenWrt-mihomo" "main" "pkg"   #mihomo
UPDATE_PACKAGE "luci-app-openclash" "vernesong/OpenClash" "dev" "pkg"  #openclash

#UPDATE_PACKAGE "luci-app-alist" "sbwml/luci-app-alist" "master"   #alist
#UPDATE_PACKAGE "luci-app-mosdns" "sbwml/luci-app-mosdns" "v5"  #mosdns
UPDATE_PACKAGE "gecoosac" "lwb1978/openwrt-gecoosac" "main"    #集客 AC OpenWRT 插件 2.1 版
UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main"   #tailscale
UPDATE_PACKAGE "luci-app-wolplus" "VIKINGYFY/luci-app-wolplus" "main"   #网络唤醒

UPDATE_PACKAGE "lazyoop" "lazyoop/networking-artifact" "main"

if [[ $WRT_REPO != *"immortalwrt"* ]]; then
	UPDATE_PACKAGE "qmi-wwan" "immortalwrt/wwan-packages" "master" "pkg"
fi

#更新软件包版本
UPDATE_VERSION() {
	local PKG_NAME=$1
	local PKG_MARK=${2:-not}
	local PKG_FILES=$(find ./ ../feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

	echo " "

	if [ -z "$PKG_FILES" ]; then
		echo "$PKG_NAME not found!"
		return
	fi

	echo "$PKG_NAME version update has started!"

	for PKG_FILE in $PKG_FILES; do
		local PKG_REPO=$(grep -Pho 'PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)' $PKG_FILE | head -n 1)
		local PKG_VER=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease|$PKG_MARK)) | first | .tag_name")
		local NEW_VER=$(echo $PKG_VER | sed "s/.*v//g; s/_/./g")
		local NEW_HASH=$(curl -sL "https://codeload.github.com/$PKG_REPO/tar.gz/$PKG_VER" | sha256sum | cut -b -64)
		local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")

		echo "$OLD_VER $PKG_VER $NEW_VER $NEW_HASH"

		if [[ $NEW_VER =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
			sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
			sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
			echo "$PKG_FILE version has been updated!"
		else
			echo "$PKG_FILE version is already the latest!"
		fi
	done
}

#UPDATE_VERSION "软件包名" "测试版，true，可选，默认为否"
UPDATE_VERSION "sing-box"
UPDATE_VERSION "tailscale"
