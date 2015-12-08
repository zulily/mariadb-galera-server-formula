{% from 'mariadb-galera-server/map.jinja' import mariadb_galera_server with context %}


/etc/mysql/my.cnf:
  file.managed:
    - source: salt://mariadb-galera-server/files/my.cnf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - service: {{ mariadb_galera_server.package }}


# need a conf.d overrides file, use path from map.jinja
/etc/mysql/conf.d/galera_cluster.cnf:
  file.managed:
    - source: salt://mariadb-galera-server/files/galera_cluster.cnf
    - template: jinja
    - user: mysql
    - group: root
    - mode: 400
    - require:
      - file: /etc/mysql/my.cnf
      - service: {{ mariadb_galera_server.package }}

# Don't restart mysql due to a config change, unless we
# think this is the initial install.  For some reason,
# a non-first_member restart of mysql erroneously returns a non-zero
# status code, so make sure to always return true to quiet warnings...
{% set first_run = salt['cmd.retcode']('test -e /etc/mysql/conf.d/galera_cluster.cnf') %}
{% if first_run %}
mariadb_initial_restart:
  cmd.run:
  {%- if salt['pillar.get']('mariadb_galera_server:settings:members:' + grains['host'] + ':first_member', False) %}
    - name: /etc/init.d/mysql stop ; pkill -9 mysql* ; /etc/init.d/mysql start --wsrep-new-cluster
  {%- else %}
    - name: /etc/init.d/mysql restart || /bin/true
  {%- endif %}
    - require:
      - file: /etc/mysql/conf.d/galera_cluster.cnf
{% endif %}
