#!/bin/bash
#
# warnquota-ng v0.50 installer
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

if [ `which python3`x == x ]; then
    if [ `which python`x == x ]; then
        echo No python interpreter was found. Install Python 3 first.
        exit 1
    else
        if [ `python --version|cut -f2 -d" "|cut -f1 -d.` -eq 3 ]; then
            PYTHONBINPATH=`which python`
            echo Python 3 found at: ${PYTHONBINPATH}
        else
            echo Python interpreter was found, but not version 3. Install Python 3 first.
            exit 1
        fi
    fi
else
    PYTHONBINPATH=`which python3`
    echo Python 3 found at: ${PYTHONBINPATH}
fi

if [ ${WQNG_RQPATH}x == x ]; then
    echo \"repquota\" not found, please install quota tools first, or check PATH
    exit 1
fi

echo -n Checking repquota version...\ 
RQVERSTRING=`${WQNG_RQPATH} --version|head -n 1|cut -d" " -f4`
RQVERMAJOR=`echo ${RQVERSTRING}|cut -d. -f1`
RQVERMINOR=`echo ${RQVERSTRING}|cut -d. -f2`
if [ ${RQVERMAJOR} -lt 4 ]; then
    echo WARNING: warnquota-ng was tested only with repquota version \>= 4.00. Your version is: ${RQVERSTRING} \(It might work anyway.\)
    WQNG_REPQUOTACSVFORMAT=False
elif [ ${RQVERMAJOR} -gt 4 ]; then
    WQNG_REPQUOTACSVFORMAT=True
else
    if [ ${RQVERMINOR} = 0 ] || [ ${RQVERMINOR} = 00 ] || [ ${RQVERMINOR} = 01 ]; then
        WQNG_REPQUOTACSVFORMAT=False
    else
        WQNG_REPQUOTACSVFORMAT=True
    fi
fi
echo -n ${RQVERMAJOR}.${RQVERMINOR} \(CSV format available:\ 
if [ ${WQNG_REPQUOTACSVFORMAT} = True ]; then
    echo yes\)
else
    echo no\)
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
    tail -n +3 warnquota-ng.conf.in | sed s/WQNG_HOSTNAME/${WQNG_HOSTNAME}/g | sed s/WQNG_REPQUOTACSVFORMAT/${WQNG_REPQUOTACSVFORMAT}/g > /tmp/wqng.config.tail.tmp
    head -2 warnquota-ng.conf.in > /tmp/wqng.config.head.tmp
    if [ ${WQNG_CONFDIR} != /etc/warnquota-ng ]; then
        echo 'configfiledir = "'${WQNG_CONFDIR}'";' >> /tmp/wqng.config.head.tmp
    fi
    if [ ${WQNG_RQPATH} != /usr/sbin/repquota ]; then
        echo 'repquotapathcmd = "'${WQNG_RQPATH}'";' >> /tmp/wqng.config.head.tmp
    fi
    if [ ${WQNG_STATEDIR} != /var/lib/warnquota-ng ]; then
        echo 'warnquotastatedir = "'${WQNG_STATEDIR}'";' >> /tmp/wqng.config.head.tmp
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
echo \#\!${PYTHONBINPATH} > ${WQNG_BINARYPATH}/warnquota-ng
tail -n +2 warnquota-ng >> ${WQNG_BINARYPATH}/warnquota-ng
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

echo Installing man page
if [ ! -f warnquota-ng.8 ]; then
    echo man page warnquota-ng.8 not found in current directory. non-fatal, but there will be no man page for warnquota-ng.
else
    if [ `which mandb`x == x ]; then
        echo no mandb found, so not installing page for warnquota-ng
    else
        if [ ! -d /usr/share/man/man8 ]; then
            echo directory for man chapter 8 does not exist, so not installing page for warnquota-ng
        else
            cp warnquota-ng.8 /usr/share/man/man8/warnquota-ng.8
            chmod 644 /usr/share/man/man8/warnquota-ng.8
            if [ `which gzip`x != x ]; then
                gzip -f /usr/share/man/man8/warnquota-ng.8
            fi
            mandb -q
        fi
    fi
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
