---
title: Proxmox Backup and Restore
description: Short thing for how to backup and restore with proxmox
date: "2025-08-05T00:00:00Z"
categories:
  - Proxmox
tags:
  - Proxmox
  - Backup
  - Restore
---

# Intro

Backup and restore from CLI with Proxmox

## Backup

```
vzdump --compress lzo 100 --dumpdir /root/vm/
```

## Restore

```
qmrestore --storage local-lvm vzdump-qemu-*.vma.lzo 100
```
