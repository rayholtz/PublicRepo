#!/bin/bash

$name = $1
$IP = $2

sudo nmcli connection modify ens192 IPv4.address 10.150.102.$IP/24
sudo nmcli connection modify ens192 IPv4.gateway 10.150.102.1
sudo nmcli connection modify ens192 IPv4.dns 10.150.102.17
sudo nmcli connection modify ens192 +IPv4.dns 10.150.90.10
sudo nmcli connection modify ens192 IPv4.method manual

sudo nmcli networking off sudo nmcli networking on


cat /etc/machine-id
sudo rm /etc/machine-id
sudo systemd-machine-id-setup
cat /etc/machine-id


hostnamectl
sudo hostnamectl set-hostname $name
hostnamectl

less /etc/hosts
sudo sed -i 's/$/ $name $name.aecia.net/' /etc/hosts
less /etc/hosts

sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config

