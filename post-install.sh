# Set up software source
sed -i 's|downloads\.immortalwrt\.org|immortalwrt.kyarucloud.moe|g' /etc/apk/repositories.d/distfeeds.list
# Set up OpenWrt-momo
curl -sSfL https://github.com/nikkinikki-org/OpenWrt-momo/raw/refs/heads/main/feed.sh | ash
# Set up NaiveProxy with sing-box (libcronet.so)
curl -L -o /usr/bin/libcronet.so "https://github.com/SagerNet/cronet-go/releases/latest/download/libcronet-linux-arm64.so" \
&& chmod 0755 /usr/bin/libcronet.so