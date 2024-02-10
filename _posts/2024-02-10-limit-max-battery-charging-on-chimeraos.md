---
title: Limit max battery charging on ChimeraOS
description: How I limit max charge on ChimeraOS, in order to maximize battery capacity
categories:
  - chimeraos
tags:
  - chimeraos
  - battery
---

# Intro

ChimeraOS is a great SteamOS-alternative, which serves as an appliance, that appliance introduces the ItJustWorks-factor,
but hinders the "I want to edit-something"-factor.

I use it on a laptop, but I can't remove the battery on that laptop - and I don't want to have the battery constantly charged to 100%.

## Systemd to the rescue.

/home/gamer/.config/systemd/user/battery-limiter.service
````shell
[Unit]
Description=Battery Limiter

[Service]
Type=simple
ExecStart=/home/gamer/battery-limit.sh
````

/home/gamer/.config/systemd/user/battery-limiter.timer
````shell
[Unit]
Description=Battery Limiter

[Timer]
Unit=battery-limiter.service
OnBootSec=15m
OnUnitInactiveSec=15m
OnActiveSec=1s

[Install]
WantedBy=timers.target
````

Replace `INSERTPASSWORDHERE` with the currently set password for the gamer-account, by default that is gamer.
/home/gamer/battery-limit.sh
````shell
#!/bin/bash
echo INSERTPASSWORDHERE | sudo -S /bin/bash -c 'echo 60 > /sys/class/power_supply/BAT0/charge_control_end_threshold'
````

Activate the timer
````bash
mkdir -p /home/gamer/.config/systemd/user/timers.target.wants; ln -s /home/gamer/.config/systemd/user/regular-maintenance.timer /home/gamer/.config/systemd/user/timers.target.wants/regular-maintenance.timer
````


# Outro

I documented this based on memory and a semi-recent backup, so it might not be 100% correct - but the most important bits should be present and "good enough".