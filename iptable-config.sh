#!/usr/bin/env bash

IPTABLES=/sbin/iptables

# Tor's TransPort
_trans_port="9040"

# Tor's DNSPort
_dns_port="5353"

# your internal interface
_inc_if="wlan0"

$IPTABLES -F
$IPTABLES -t nat -F

$IPTABLES -t nat -A PREROUTING -i $_inc_if -p udp --dport 53 -j REDIRECT --to-ports $_dns_port
$IPTABLES -t nat -A PREROUTING -i $_inc_if -p udp --dport $_dns_port -j REDIRECT --to-ports $_dns_port
$IPTABLES -t nat -A PREROUTING -i $_inc_if -p tcp --syn -j REDIRECT --to-ports $_trans_port

$IPTABLES -I INPUT -i $_inc_if -p udp --dport 67:68 --sport 67:68 -j ACCEPT
