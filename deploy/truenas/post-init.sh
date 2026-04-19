#!/bin/sh
# TrueNAS SCALE Post Init script for ugreen-truenas-leds.
#
# Register via: System Settings > Advanced > Init/Shutdown Scripts > Add
#   Type:    Script
#   Script:  /mnt/POOL/apps/truenas-leds/post-init.sh   (must live on a data pool)
#   When:    Post Init
#   Timeout: 10
#
# Loads the kernel modules the LED controller container needs to access the
# SMBus. Safe to run repeatedly; no-ops if the modules are already loaded.

modprobe i2c-dev 2>/dev/null || true
modprobe i2c-i801 2>/dev/null || true
