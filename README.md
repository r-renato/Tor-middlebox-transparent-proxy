<h1>TorBox Transparent Proxy using Raspberry PI</h1>
<p>This guide is builded to help you to build a Tor Middlebox using a Raspberry Pi <a href="https://www.raspberrypi.org/products/raspberry-pi-1-model-b-plus/">(Model B Plus)</a>.</p>

<h2>Content index</h2>
<ol>
<li><a href="#requirements">Requirements</a></li>
<li><a href="#install_so">Installing operating system image</a></li>
<li><a href="#update_so">Updating operating system</a></li>
<li><a href="#config_network">Configuring the network</a></li>
<li><a href="#config_dhcp_dns">Configuring the DHCP and its CACHE (dnsmasq)</a></li>
<li><a href="#config_wlan_ap_host">Configuring the WLAN-AP-Host (hostapd)</a></li>
<li><a href="#config_firewall">Enable firewall</a></li>
<li><a href="#install_tor">Installing Tor</a></li>
<li><a href="#config_tor">Configuring Tor</a></li>
<li><a href="#config_obfs4proxy">Configuring obfs4proxy</a></li>
<li><a href="#config_crontab">Configuring crontab</a></li>
</ol>

<h2 id="requirements">Requirements</h2>
<h3>Hardware</h3>
<ol>
<li>Raspberry Pi <a href="https://www.raspberrypi.org/products/raspberry-pi-1-model-b-plus/">(Model B Plus)</a> or higher.</li>
<li>Micro SD card class 10 at least V30. Example <a href="https://www.sandisk.com/home/memory-cards/microsd-cards/high-endurance-microsd">(SanDisk® High Endurance)</a></li>
<li>(Optional) USB Wireless WiFi Adapter. Example <a href="https://www.tp-link.com/en/home-networking/adapter/tl-wn722n/">(USB TP-LINK TL-WN722N Wifi adapter)</a></li>
</ol>

<h2 id="install_so">Installing operating system image</h2>
<p>Follow the Raspberry Pi instructions to <a href="https://www.raspberrypi.org/documentation/installation/installing-images/">installing operating system images</a></p>


<h2 id="update_so">Updating operating system</h2>

```
sudo apt-get update ; sudo apt-get upgrade -y ; sudo apt-get install -y rpi-update ; sudo apt-get dist-upgrade -y
sudo apt-get clean ; sudo apt-get autoclean ; sudo apt-get autoremove
sudo reboot
sudo rpi-update
sudo reboot
```
<h2 id="config_network">Configuring the network</h2>
<p>Installing the necessary packages using following command:</p>

```
sudo apt-get install -y hostapd \
dnsmasq dnsutils tcpdump iftop vnstat links2 debian-goodies dirmngr
```
<p>Don't start dnsmasq automatically after booting the system</p>

```
sudo update-rc.d dnsmasq disable
```
<p>Edit the following file:</p>

```
sudo vi /etc/network/interfaces.wlan0
```
<p>and put inside</p>

```
# Localhost
auto lo
iface lo inet loopback

# Ethernet
auto eth0
iface eth0 inet dhcp

# WLAN-Interface
allow-hotplug wlan0
iface wlan0 inet static
  address 192.168.222.1
  netmask 255.255.255.0
```
<p>so replace the configurations</p>

```
sudo cp /etc/network/interfaces /etc/network/interfaces.org
sudo cp /etc/network/interfaces.wlan0 /etc/network/interfaces
```
<p>Check if the "dhcpcd" is active: "Active: active (running)" using the following command:</p>

```
sudo systemctl status dhcpcd
```

<p>or</p>

```
sudo systemctl status hostapd | grep "active (running)" | wc -l
```
<p>If the service running, the edit the file </p>

```
sudo vi /etc/dhcpcd.conf
```
<p>and add to end file:</p>

```
# WLAN deny
denyinterfaces wlan0
```
<p>so reboot the system with the command:</p>

```
sudo reboot
```
<p>Check if the WLAN is present</p>

```
ip l 
```
<h2 id="config_dhcp_dns">Configuring the DHCP and its CACHE (dnsmasq)</h2>
<p>Edit the file</p>

```
sudo vi /etc/dnsmasq.conf.torbox
```
<p>and punt inside:</p>

```
# DHCP-Server active for WLAN-Interface
interface=wlan0

# DHCP-Server not active for Ethernet
no-dhcp-interface=eth0

# IPv4-address range and Lease-Time
dhcp-range=192.168.222.100,192.168.222.150,24h

# DNS
dhcp-option=option:dns-server,192.168.222.1

# Logging
# **Decommentando** log-queries, i log del di dnsmaq verranno registarti in /var/log/daemon.log
# **Decommentando** log-facility, i log verranno registrati nel file specificato
log-facility=/var/log/dnsmasq.log
log-queries
```

<p>Managing the dnsmasq log rotation; edit or change the following file using:</p>

```
sudo vi /etc/logrotate.d/dnsmasq
```

<p>so replace its content</p>

```
/var/log/dnsmasq.log {
monthly
missingok
notifempty
delaycompress
sharedscripts
postrotate
[ ! -f /var/run/dnsmasq.pid ] || kill -USR2 `cat /var/run/dnsmasq.pid`
endscript
create 0640 dnsmasq dnsmasq
}
```
<p>Replace the dnsmasq configurations</p>

```
sudo cp /etc/dnsmasq.conf /etc/dnsmasq.conf.org
sudo cp /etc/dnsmasq.conf.torbox /etc/dnsmasq.conf
```
<p>Check the configuration before activate</p>

```
dnsmasq --test -C /etc/dnsmasq.conf
```
<p>or test it</p>

```
dnsmasq -C ./dnsmasq-dhcp-only.conf -d
```
<p>Restart the dnsmasq and check her status</p>

```
sudo systemctl restart dnsmasq
sudo systemctl status dnsmasq
```
<p>Enable dnsmasq to start with the system</p>

```
sudo systemctl abilita dnsmasq
```
<h2 id="config_wlan_ap_host">Configuring the WLAN-AP-Host (hostapd)</h2>
<p>Edit the file</p>

```
/etc/hostapd/hostapd.conf
```
<p>and replace with</p>

```
# WLAN-Router-Mode

# Interface and driver
interface=wlan0
#driver=nl80211

# WLAN-Configurations-Standard
ssid=grott
hw_mode=g
ieee80211n=1
ieee80211d=1
country_code=FR
wmm_enabled=1


# WLAN-Encoding
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]
macaddr_acl=0
ignore_broadcast_ssid=0

# WLAN-Configurations-Parameters
channel=11
wpa_passphrase=change-me
```
<p>and apply the necessary rights using the command:</p>

```
sudo chmod 600 /etc/hostapd/hostapd.conf
```
<p>Start manually the hostapd </p>

```
sudo hostapd -dd /etc/hostapd/hostapd.conf
```
<p>and check if the output contains</p>

```
...
wlan0: stato dell'interfaccia COUNTRY_UPDATE-> ENABLED
...
wlan0: AP-ENABLED
... 
```
<p>If this working fine then edit the file</p>

```
sudo vi /etc/default/hostapd
```
<p>and add to end</p>

```
RUN_DAEMON=yes
DAEMON_CONF="/etc/hostapd/hostapd.conf"
```
<p>Starting the hostapd</p>

```
sudo systemctl unmask hostapd # Optional
sudo systemctl enable hostapd
sudo systemctl start hostapd
```
<h2 id="config_firewall">Enable firewall</h2>
<p>Edit the following file:</p>

```
sudo vi /etc/network/interfaces.wlan0
```
<p>and add to end</p>

```
# IP-Forwarding MUST be disabled
up sysctl -w net.ipv4.ip_forward=0
up sysctl -w net.ipv6.conf.all.forwarding=0

# hostapd and dnsmasq restart
up service hostapd restart
up service dnsmasq restart
```
<p>so replace the configuration</p>

```
sudo cp /etc/network/interfaces.wlan0 /etc/network/interfaces
```
<h2 id="install_tor">Installing Tor</h2>

```
sudo apt-get install -y tor obfs4proxy \
gvfs gvfs-fuse gvfs-backends gvfs-bin \
ipheth-utils libimobiledevice-utils usbmuxd \
wicd wicd-curses \
python3-setuptools ntpdate screen
```
<p>Edit the file</p>

```
sudo vi /etc/apt/sources.list
```
<p>and add to end</p>

```
deb https://deb.torproject.org/torproject.org stretch main
deb-src https://deb.torproject.org/torproject.org stretch main
```

<p>so execute the following commands to build last version of tor (this operations can be very long)</p>

```
gpg --keyserver keys.gnupg.net --recv A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y build-essential fakeroot devscripts
sudo apt build-dep tor deb.torproject.org-keyring
if [ -d debian-packages ] ; then rm -r debian-packages ; fi
mkdir ~/debian-packages; cd ~/debian-packages
apt source tor; cd tor-*
debuild -rfakeroot -uc -us; cd ..
sudo dpkg -i tor_*.deb
```

<h2 id="config_tor">Configuring Tor</h2>

```
# Transport
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsSuffixes .onion,.exit
AutomapHostsOnResolve 1
TransPort 127.0.0.1:9040 IsolateClientAddr IsolateClientProtocol IsolateDestAddr IsolateDestPort
TransPort 192.168.222.1:9040 IsolateClientAddr IsolateClientProtocol IsolateDestAddr IsolateDestPort

# DNS (local and wlan interfaces)
DNSPort 127.0.0.1:5353
DNSPort 192.168.222.1:5353

# SOCKS (eth interface)
SocksPort 192.168.1.4:9100

# Control
ControlPort 127.0.0.1:9051
#HashedControlPassword <hashpassword> 
# use 'tor --hash-password <password>' to generate

# Debugging
DisableDebuggerAttachment 0
Log notice file /var/log/tor/notices.log
```

<p>restart tor and testing it</p>

```
sudo systemctl restart tor
echo -e 'PROTOCOLINFO\r\n' | nc 127.0.0.1 9051
```

<h2 id="config_obfs4proxy">Configuring obfs4proxy</h2>

```sudo setcap 'cap_net_bind_service=+ep' /usr/bin/obfs4proxy```
<h2 id="config_crontab">Configuring crontab</h2>

<p>put the following bash files in the pi home (/home/pi)</p>

```
iptable-clear.sh
iptable-config.sh
torbox-boot.sh
```
<p>edit the root crontab</p>

```
sudo crontab -e
```
<p>so put inside</p>

```
@reboot /home/pi/torbox-boot.sh >> /tmp/boot.log 2>&1
```

<p>reboot the system, the tor middlebox transparent proxy is ready.</p>

```
sudo reboot
```