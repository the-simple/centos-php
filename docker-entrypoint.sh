#!/bin/bash
set -e

rm -f /etc/cron.d/magento-cron;
if [ -z "$MAGE_CRON_EXPR" ]; then
    MAGE_CRON_EXPR="*/10 * * * *"
fi
if [ -z "$MAGE_CRON_USER" ]; then
    MAGE_CRON_USER=root
fi
if [ -z "$SERVER_LISTEN_PORT" ]; then
    SERVER_LISTEN_PORT=80
fi

if [ ! -z "$MAGE_ROOT" ]; then

    LINE="$MAGE_CRON_EXPR $MAGE_CRON_USER $(which sh) $MAGE_ROOT/cron.sh >> $MAGE_ROOT/var/log/cron.log 2>&1"

    echo 'SHELL=/bin/bash' > /etc/cron.d/magento-cron
    echo 'PATH=/sbin:/bin:/usr/sbin:/usr/bin' >> /etc/cron.d/magento-cron
    echo 'MAILTO=root' >> /etc/cron.d/magento-cron
    echo "$LINE" >> /etc/cron.d/magento-cron

    if [ ! -z "$MAGE_CUSTOM_CRON" ]; then
         IFS=':' read -r -a crons <<< "$MAGE_CUSTOM_CRON";
        for cronexpr in "${crons[@]}"; do
            echo "### Custom Cron Lines" >> /etc/cron.d/magento-cron
            echo "$cronexpr" >> /etc/cron.d/magento-cron
        done
    fi

    chown root:root /etc/cron.d/magento-cron
    chmod 644 /etc/cron.d/magento-cron
fi

exec "$@"
