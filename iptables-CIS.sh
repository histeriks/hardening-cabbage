#! /bin/sh
 iptables -F
 iptables -P INPUT DROP
 iptables -P OUTPUT DROP
 iptables -P FORWARD DROP
 iptables -A INPUT -i lo -j ACCEPT
 iptables -A OUTPUT -o lo -j ACCEPT
 iptables -A INPUT -s 127.0.0.0/8 -j DROP
 iptables -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
 iptables -A OUTPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT
 iptables -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT
 iptables -A INPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
 iptables -A INPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT
 iptables -A INPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT
 iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT
 iptables -A INPUT -p tcp --dport 372 -m state --state NEW -j ACCEPT
 iptables -A INPUT -p tcp --dport 1514 -m state --state NEW -j ACCEPT
 iptables -A INPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT
 iptables -A INPUT -p tcp --dport 443 -m state --state NEW -j ACCEPT
 iptables -A INPUT -p tcp --dport 3306 -m state --state NEW -j ACCEPT
