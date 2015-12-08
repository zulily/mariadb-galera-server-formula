/etc/mysql/cert.pem:
  file.managed:
    - user: mysql
    - group: root
    - mode: 644
    - contents_pillar: mariadb_galera_server_ssl:cert

/etc/mysql/key.pem:
  file.managed:
    - user: mysql
    - group: root
    - mode: 600
    - contents_pillar: mariadb_galera_server_ssl:key
