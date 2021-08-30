chmod -R 755 /bin /boot /etc/ /home /lib /mnt /opt /run /sbin /srv /usr /var

chmod -R 1777 /tmp
chmod -R 555 /sys
chmod -R 700 /root

chown manjaro:manjaro /usr/bin/sudo && chmod 4755 /usr/bin/sudo