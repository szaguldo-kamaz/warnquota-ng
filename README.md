# warnquota-ng
An easy to use tool for sophisticated quota limit notifications for Linux systems, intended to provide a replacement for the original "warnquota" tool.

## Features
 - send "over quota" alerts when a limit is reached
 - send notifications (pre-alerts) before the actual limit is reached (configurable %)
 - send confirmation when quota is below the limit again
 - sends repeated reminders based on configured intervals
 - notifies both the user and an admin
 - configurable to alert only the admin regarding inode quota limits
 - arbitrary e-mail addresses for alerting users and admins
   (not required to be on the same system, e.g. can be a gmail address)
 - multi-language support
   (currently English and Hungarian languages)
 - per-user configuration

## Requirements
 - Python 3 (tested with 3.2)
 - quota tools (repquota)
 - access to an SMTP server
 - cron

## Installing
 1. Run **warnquota-ng.install.sh** as root (modify the env vars if you don't like the default paths)
 2. Revise the generated configuration files
