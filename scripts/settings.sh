#!/bin/bash

# remove attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
# modify immortalwrt.lan IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
# add compile date flag
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

WIFI_SH=$(find ./target/linux/{mediatek/filogic,qualcommax}/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh")
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_SH" ]; then
	# modify SSID
	sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
	# modify WiFi Password
	sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_NETPD'/g" $WIFI_SH
elif [ -f "$WIFI_UC" ]; then
	# modify SSID
	sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
	# modify WiFi Password
	sed -i "s/key='.*'/key='$WRT_NETPD'/g" $WIFI_UC
	# modify WiFi Region
	sed -i "s/country='.*'/country='CN'/g" $WIFI_UC
	# modify WiFi Encryption
	sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" $WIFI_UC
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
# modify LuCi/gateway IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
# modify router hostname
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

# configuration for luci
echo "CONFIG_PACKAGE_luci=y" >> ./.config
# echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config

# adjustment for extra luci-apps
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

# adjustments for quancomm devices
DTS_PATH="./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/"
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	# disable nss-related feed
	# echo "CONFIG_FEED_nss_packages=n" >> ./.config
	echo "CONFIG_FEED_sqm_scripts_nss=n" >> ./.config
	# disable sqm-nss packages
	echo "CONFIG_PACKAGE_luci-app-sqm=n" >> ./.config
	echo "CONFIG_PACKAGE_sqm-scripts-nss=n" >> ./.config
	# set NSS version
	echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=n" >> ./.config
	if [[ "${WRT_CONFIG,,}" == *"ipq50"* ]]; then
		echo "CONFIG_NSS_FIRMWARE_VERSION_12_2=y" >> ./.config
	else
		echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> ./.config
	fi
	# USB
	echo "CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y" >> ./.config
fi

#编译器优化
if [[ $WRT_TARGET != *"X86"* ]]; then
	echo "CONFIG_TARGET_OPTIONS=y" >> ./.config
	echo "CONFIG_TARGET_OPTIMIZATION=\"-O2 -pipe -march=armv8-a+crypto+crc -mcpu=cortex-a53+crypto+crc -mtune=cortex-a53\"" >> ./.config
fi