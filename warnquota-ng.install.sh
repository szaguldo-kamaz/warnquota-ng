#!/bin/bash
#
# warnquota-ng v0.30beta installer
#
# author: David Vincze
# github.com/szaguldo-kamaz/
# david.vincze@webcode.hu
#
#

WQNG_BINARYPATH=/usr/sbin
WQNG_CONFDIR=/etc/warnquota-ng
# this needs to be on permanent storage (so /var/run, /tmp ... won't do)
WQNG_STATEDIR=/var/lib/warnquota-ng
WQNG_HOSTNAME=`hostname`
WQNG_RQPATH=`which repquota`

if [ `id -u` -ne 0 ]; then
    echo Probably you need to be root, but continuing anyway...
fi

if [ ${WQNG_RQPATH}x == x ]; then
    echo \"repquota\" not found, please install quota tools first, or check PATH
    exit 1
fi

if [ ! -f warnquota-ng.conf.in ]; then
    echo warnquota-ng.conf.in not found in current directory
    exit 1
fi

if [ ! -f warnquota-ng.crontab ]; then
    echo warnquota-ng.crontab not found in current directory
    exit 1
fi

if [ ! -f warnquota-ng ]; then
    echo warnquota-ng not found in current directory
    exit 1
fi

echo Creating config and state directories: $WQNG_CONFDIR $WQNG_STATEDIR
if [ -d $WQNG_CONFDIR ]; then
    echo config directory $WQNG_CONFDIR already exists.
else
    mkdir $WQNG_CONFDIR
fi
if [ $? -ne 0 ]; then
    echo ERROR creating config dir: $WQNG_CONFDIR
    exit 2
fi
if [ -d $WQNG_STATEDIR ]; then
    echo state directory $WQNG_STATEDIR already exists.
else
    mkdir $WQNG_STATEDIR
fi
if [ $? -ne 0 ]; then
    echo ERROR state config dir: $WQNG_STATEDIR
    exit 2
fi

echo Setting permissions on config and state directories
chmod 700 $WQNG_CONFDIR $WQNG_STATEDIR
if [ $? -ne 0 ]; then
    echo ERROR setting permissions on config/state dirs: $WQNG_CONFDIR $WQNG_STATEDIR
    exit 2
fi

echo Preparing default config file \(using hostname: ${WQNG_HOSTNAME}\)
if [ -f ${WQNG_CONFDIR}/warnquota-ng.conf ]; then
    echo config file already exists\! Leaving it as it is...
else
    tail -n +3 warnquota-ng.conf.in | sed s/WQNG_HOSTNAME/${WQNG_HOSTNAME}/g > /tmp/wqng.config.tail.tmp
    head -2 warnquota-ng.conf.in > /tmp/wqng.config.head.tmp
    if [ ${WQNG_CONFDIR} != /etc/warnquota-ng ]; then
        echo 'configfiledir="'${WQNG_CONFDIR}'";' >> /tmp/wqng.config.head.tmp
    fi
    if [ ${WQNG_RQPATH} != /usr/sbin/repquota ]; then
        echo 'repquotapathcmd="'${WQNG_RQPATH}'";' >> /tmp/wqng.config.head.tmp
    fi
    if [ ${WQNG_STATEDIR} != /var/lib/warnquota-ng ]; then
        echo 'warnquotastatedir="'${WQNG_STATEDIR}'";' >> /tmp/wqng.config.head.tmp
    fi
    if [ `cat /tmp/wqng.config.head.tmp|wc -l` -gt 2 ]; then
        echo >> /tmp/wqng.config.head.tmp
    fi
    cat /tmp/wqng.config.head.tmp /tmp/wqng.config.tail.tmp > ${WQNG_CONFDIR}/warnquota-ng.conf
    if [ $? -ne 0 ]; then
        echo ERROR while preparing configuration file: ${WQNG_CONFDIR}/warnquota-ng.conf
        exit 2
    fi
    chmod 00644 ${WQNG_CONFDIR}/warnquota-ng.conf
    if [ $? -ne 0 ]; then
        echo ERROR while setting permissions on configuration file: ${WQNG_CONFDIR}/warnquota-ng.conf
        exit 2
    fi
    rm -f /tmp/wqng.config.head.tmp /tmp/wqng.config.tail.tmp
fi

echo Copying sample fs config
cp -f warnquota-ng.fs.SAMPLE.conf ${WQNG_CONFDIR}/
if [ $? -ne 0 ]; then
    echo ERROR while copying warnquota-ng.fs.SAMPLE.conf to ${WQNG_CONFDIR}/
    exit 2
fi

echo Installing executable
cp -f warnquota-ng ${WQNG_BINARYPATH}/
if [ $? -ne 0 ]; then
    echo ERROR while copying executable into ${WQNG_BINARYPATH}/
    exit 2
fi
chown root:root ${WQNG_BINARYPATH}/warnquota-ng
if [ $? -ne 0 ]; then
    echo WARNING\! Cannot set permissions on ${WQNG_BINARYPATH}/warnquota-ng
fi
chmod 00755 ${WQNG_BINARYPATH}/warnquota-ng
if [ $? -ne 0 ]; then
    echo WARNING\! Cannot set permissions on ${WQNG_BINARYPATH}/warnquota-ng
fi

echo Setting up cron
if [ -f /etc/cron.d/warnquota-ng ]; then
    echo crontab already exists\! Leaving it as it is...
else
    cp warnquota-ng.crontab /etc/cron.d/warnquota-ng
    if [ $? -ne 0 ]; then
        echo ERROR while preparing crontab \(/etc/cron.d/warnquota-ng\)
        exit 2
    fi
fi