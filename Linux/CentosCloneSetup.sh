#!/bin/bash

name=$1
IP=$2

sudo nmcli connection modify ens192 IPv4.address 10.150.102.${2}/24
sudo nmcli connection modify ens192 IPv4.gateway 10.150.102.1
sudo nmcli connection modify ens192 IPv4.dns 10.150.102.17
sudo nmcli connection modify ens192 +IPv4.dns 10.150.90.10
sudo nmcli connection modify ens192 IPv4.method manual

sudo nmcli networking off 
sudo nmcli networking on

ip addr show dev ens192


cat /etc/machine-id
sudo rm /etc/machine-id
sudo systemd-machine-id-setup
cat /etc/machine-id


hostnamectl
sudo hostnamectl set-hostname $1
hostnamectl

sudo sed -i "s/$/ ${1} ${1}.aecia.net/' /etc/hosts
cat /etc/hosts

sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
sudo cat /etc/ssh/sshd_config | grep Root
