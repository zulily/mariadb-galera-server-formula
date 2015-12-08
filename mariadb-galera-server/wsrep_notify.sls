# This sends e-mail notifications regarding member status changes
# A script is not included to handle this, but one such example may be found here:
#
# https://github.com/gguillen/galeranotify
#
#/usr/local/bin/galera_notify:
#  file.managed:
#    - source: salt://mariadb-galera-server/files/galera_notify
#    - mode: 555
#    - user: root
#    - group: root
