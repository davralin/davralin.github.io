---
title: Switch oracle-cloud-instances to Talos
description: Switch oracle-cloud-instances to Talos, mainly the free-version
date: "2022-10-10T21:26:03Z"
categories:
  - talos
  - oracle-cloud
tags:
  - talos
  - oracle-cloud
---

# amd64

````bash
destination_disk=/dev/sda
talos_version=v1.2.5


wget https://github.com/talos-systems/talos/releases/download/${talos_version}/nocloud-amd64.raw.xz
wipefs -af $destination_disk
xzcat nocloud-*64.raw.xz | dd of=${destination_disk} bs=1M

echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger

````

# arm64

````bash
apt update && apt install qemu-utils -y

talos_version=v1.2.5
cloud_instance=oracle
mkdir /tmp/temp && mount -t tmpfs tmpfs /tmp/temp/ && cd /tmp/temp
wget https://github.com/talos-systems/talos/releases/download/${talos_version}/${cloud_instance}-arm64.qcow2.xz
xz -d ${cloud_instance}-arm64.qcow2.xz
qemu-img convert -f qcow2 -O raw ${cloud_instance}-arm64.qcow2 ${cloud_instance}-arm64.img
wipefs --all --force /dev/sda1
wipefs --all --force /dev/sda15
wipefs --all --force /dev/sda
sync
echo 3 > /proc/sys/vm/drop_caches
dd if=${cloud_instance}-arm64.img of=/dev/sda bs=1M status=progress
sync
echo 3 > /proc/sys/vm/drop_caches

echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger

````

