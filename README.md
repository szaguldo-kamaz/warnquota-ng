# warnquota-ng
An easy to use tool for sophisticated quota limit notifications for Linux systems, intended to provide a replacement for the original "warnquota" tool.

## Features
 - send "over quota" alerts when a limit is reached
 - "real-time": checking every few minutes (default is every 5 mins), not just once a day
 - send notifications (pre-alerts) before the actual limit is reached (configurable %)
 - send confirmation when quota is below the limit again
 - sends repeated reminders based on configured intervals \
 (by default: 2 hours, 12 hours, 24 hours, 3 days and 7 days after the first mail was sent)
 - notifies both the user and an admin
 - configurable to alert only the admin regarding inode quota limits \
 (as most regular users does not know about inodes or "file count")
 - arbitrary e-mail addresses for alerting users and admins \
   (not required to be on the same system, e.g. can be a gmail address)
 - multi-language support \
   (currently English and Hungarian languages)
 - uses SMTP directly with SSL/STARTTLS/AUTH support
 - per-user configuration
 - can store user configuration in LDAP directory (using warnquota-ng.schema)
 - designed with "security in mind"
   - only the fs quota info gathering is executed with elevated privileges
     - starts as root, switches to normal user keeping only the required capabilities \
       (CAP_SYS_ADMIN, CAP_DAC_OVERRIDE)
   - all other processing is done with normal user privileges

## Requirements
 - Python 3 (tested with 3.2/3.5/3.7/3.9, but newer should be just fine)
 - quota tools (repquota)
 - access to an SMTP server
 - cron
 - pyprctl (for dropping capabilities) *(optional, but recommended)*

## Installing
 1. Run **warnquota-ng.install.sh** as root (modify the env vars if you don't like the default paths)
 2. Revise the generated configuration files (define your filesystems to be monitored)
 3. *Optional:* Create customized per-user config based on warnquota-ng.fs.SAMPLE.conf
 4. *Optional:*
    - Add warnquota-ng.schema to your LDAP server configuration
    - Add warnquota-ng attributes for your users in LDAP (see warnquota-ng-modify_sample.ldif)
    - Uncomment the "warnquota-ng -L" command in the warnquota-ng cron configuration file in /etc/cron.d/
 5. *Optional:* ```pip install pyprctl```
