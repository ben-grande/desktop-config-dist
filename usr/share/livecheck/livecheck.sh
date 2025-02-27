#!/bin/bash

## Copyright (C) 2018 - 2023 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## Copyright (C) 2018 Algernon <33966997+Algernon-01@users.noreply.github.com>
## See the file COPYING for copying conditions.

set -e

## sudo /bin/lsblk
##
## NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
## sda      8:0    0  100G  1 disk
##
## 1 means read-only
## 0 means read-write

## As soon as we have at least one "0" it is concluded: not live mode.

## when using snapd:
##
## sudo /bin/lsblk
##
## NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
## loop0    7:0    0   55M  1 loop /snap/core18/1754
## loop1    7:1    0        0 loop
## loop2    7:2    0        0 loop
## loop3    7:3    0        0 loop
## loop4    7:4    0        0 loop
## loop5    7:5    0        0 loop
## loop6    7:6    0        0 loop
## loop7    7:7    0        0 loop
## sda      8:0    0  100G  0 disk
##   sda1   8:1    0  100G  0 part /
## sr0     11:0    1 1024M  0 rom

## when using snapd:
##
## sudo /bin/lsblk --noheadings --raw --output RO
##
## 1
## 1
## 0
## 0
## 0
## 0
## 0
## 0
## 0
## 0
## 0

## The following did not work with snapd:
## http://forums.whonix.org/t/wickr-me-gets-whonix-stuck-in-live-mode/9834/1
#if sudo --non-interactive /bin/lsblk --noheadings --raw --output RO | grep --invert-match "0" ; then

## Using `sudo` to run `lsblk` because `hide-hardware-info.service` makes this no longer
## readable by user `root`. Only readable by user `root`.
## https://forums.whonix.org/t/restrict-hardware-information-to-root-testers-wanted/8618/13

missing_image=""
test -f /usr/share/icons/gnome-colors-common/scalable/status/dialog-error.svg || missing_image=true
test -f /usr/share/icons/gnome-colors-common/scalable/status/dialog-warning.svg || missing_image=true
test -f /usr/share/icons/gnome-colors-common/scalable/status/gtk-info.svg || missing_image=true
test -f /usr/share/icons/gnome-colors-common/scalable/actions/dialog-apply.svg || missing_image=true

if test -f /usr/share/anon-gw-base-files/gateway || test -f /usr/share/anon-ws-base-files/workstation ; then
   homepage="https://www.whonix.org"
   sentence_ending="."
else
   homepage="https://www.kicksecure.com"
   sentence_ending=", if possible."
fi

if [ "$missing_image" = "true" ]; then
   bug_message="

(Minor bug: Missing illustrative image.)"
else
   bug_message=""
fi

## Check if execution of lsblk fails with a non-zero exit code such as in case of missing sudoers permissions.
if ! lsblk_output="$(sudo --non-interactive /bin/lsblk --noheadings --raw --output RO)" ; then
   ## lsblk exited a non-zero exit code.
   true "INFO: Running 'sudo --non-interactive /bin/lsblk --noheadings --raw --output RO' failed!"
   echo "<img>/usr/share/icons/gnome-colors-common/scalable/status/dialog-error.svg</img>"
   ## Show "Error" next to info symbol in systray.
   echo "<txt>Error</txt>"
   echo "<tool>Do not panic. Live mode detection failed. Could not determine if booted into live mode or persistent mode. Please report this bug. See: $homepage/wiki/Grub-live#Live_Check_Systray_Issues or click on the icon for more information.$bug_message</tool>"
   echo "<click>x-www-browser $homepage/wiki/Grub-live#Live_Check_Systray_Issues</click>"
   echo "<txtclick>x-www-browser $homepage/wiki/Grub-live#Live_Check_Systray_Issues</txtclick>"
   exit 0
fi
## lsblk exited with exit code 0.

if grep --no-messages --quiet 'boot=live' /proc/cmdline; then
   live_mode_environment="grub-live"
elif grep --no-messages --quiet 'root=live' /proc/cmdline; then
   live_mode_environment="ISO Live"
fi

if echo "$lsblk_output" | grep --quiet "0" ; then
   true "INFO: If at least one '0' was found. Conclusion: not all read-only. Some read-write."
   if grep --no-messages --quiet 'boot=live\|root=live' /proc/cmdline; then
      true "INFO: grub-live or ISO live is enabled."
      echo "<img>/usr/share/icons/gnome-colors-common/scalable/status/dialog-warning.svg</img>"
      ## Show "Live" next to info symbol in systray.
      echo "<txt>Live</txt>"
      echo "<tool>Live mode ($live_mode_environment) is enabled but it is still possible to write to the disk. Please power off the machine and set the disk to read-only$sentence_ending See: $homepage/wiki/Live_Mode or click on the icon for more information.$bug_message</tool>"
      echo "<click>x-www-browser $homepage/wiki/Live_Mode</click>"
      echo "<txtclick>x-www-browser $homepage/wiki/Live_Mode</txtclick>"
   else
      true "INFO: Live mode and/or ISO live is disabled."
      echo "<img>/usr/share/icons/gnome-colors-common/22x22/status/gtk-info.png</img>"
      ## Do not show "Persistent" next to info symbol in systray.
      #echo "<txt>Persistent</txt>"
      echo "<tool>You are using persistent mode. All changes to the disk will be preserved after a reboot. For using live mode, see: $homepage/wiki/Live_Mode or click on the icon for more information.$bug_message</tool>"
      echo "<click>x-www-browser $homepage/wiki/Live_Mode</click>"
      echo "<txtclick>x-www-browser $homepage/wiki/Live_Mode<txtclick>"
   fi
else
   true "INFO: No '0' is found. Therefore only '1' found. Conclusion: read-only."

   echo "<img>/usr/share/icons/gnome-colors-common/scalable/actions/dialog-apply.svg</img>"
   ## Show "Live" next to info symbol in systray.
   echo "<txt>Live</txt>"

   echo "<tool>Live mode ($live_mode_environment) is enabled. All changes to the disk will be gone after a reboot. See: $homepage/wiki/Live_Mode or click on the icon for more information.$bug_message</tool>"
   echo "<click>x-www-browser $homepage/wiki/Live_Mode</click>"
   echo "<txtclick>x-www-browser $homepage/wiki/Live_Mode</txtclick>"
fi
