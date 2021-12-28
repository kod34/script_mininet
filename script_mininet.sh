#!/bin/bash

# Create namespaces
ip netns add h1
ip netns add h2

# Create Switch
ovs-vsctl add-br s1

# Create interfaces
ip link add h1-eth0 type veth peer name s1-eth1
ip link add h2-eth0 type veth peer name s1-eth2

# Configure interfaces with respective namespaces
ip link set h1-eth0 netns h1
ip link set h2-eth0 netns h2

# Activate switch interfaces
ip link set s1-eth1 up
ip link set s1-eth2 up

# Set ports on switch
ovs-vsctl add-port s1 s1-eth1
ovs-vsctl add-port s1 s1-eth2

# Activate namespaces
ip netns exec h1 ip link set dev h1-eth0 up
ip netns exec h2 ip link set dev h2-eth0 up

# Configure ip addresses
ip netns exec h1 ip address add 192.168.111.10/24 dev h1-eth0
ip netns exec h2 ip address add 192.168.111.20/24 dev h2-eth0

# root name space
ip link add root-eth0 type veth peer name s1-root
ip link set s1-root up
ovs-vsctl add-port s1 s1-root
ip link set dev root-eth0 up
ip address add 192.168.111.1/24 dev root-eth0

# NAT
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
iptables -A FORWARD -o eth0 -i root-eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o root-eth0 -j ACCEPT
iptables -t nat -A POSTROUTING -s 192.168.111.10/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.168.111.20/24 -o eth0 -j MASQUERADE
ip netns exec h1 ip route add default via 192.168.111.1
ip netns exec h2 ip route add default via 192.168.111.1

# DNS
sed -i '17s/.*/nameserver 8.8.8.8/' /etc/resolv.conf


# How to run
# 1. Download this script on the VM
# 2. chmod +x script_mininet.sh
# 3. ./script_mininet