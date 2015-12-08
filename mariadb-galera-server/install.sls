{% from 'mariadb-galera-server/map.jinja' import mariadb_galera_server with context %}

{# Pull member-specific settings and overrides first #}
{%
    set settings_members = salt['grains.filter_by'](
        salt['pillar.get']('mariadb_galera_server:settings:members'),
        grain='host')
%}

{# Pull in base settings, then merge host-specific overrides on top #}
{%
    set mariadb_galera_server_settings = salt['grains.filter_by'](
        salt['pillar.get']('mariadb_galera_server:settings:base'),
        grain='host', merge=settings_members)
%}

# Set the initial root password for the first member only
# !!Todo!! don't set password if this is a rebuild of the first member
{% if salt['pillar.get']('mariadb_galera_server:settings:members:' + grains['host'] + ':first_member', False) %}
mariadb_galera_server_debconf:
  debconf.set:
    - name: mysql-server
    - data: {
      'mysql-server/root_password': {'type': 'password', 'value': 'change_me'},
      'mysql-server/root_password_again': {'type': 'password', 'value': 'change_me'},
      'mysql-server/start_on_boot': {'type': 'boolean', 'value': 'true'}
    }
    - require_in:
      - pkg: {{ mariadb_galera_server.package }}
{% endif %}

{{ mariadb_galera_server.framework_package }}:
  pkg.installed:
    - hold: {{ mariadb_galera_server_settings.galera_hold }}

{{ mariadb_galera_server.package }}:
  pkg.installed:
    - name: {{ mariadb_galera_server.package }}
    - hold: {{ mariadb_galera_server_settings.hold }}
    - require:
      - pkg: {{ mariadb_galera_server.framework_package }}
  service.running:
    - name: {{ mariadb_galera_server.service }}
    - enable: True
    - watch:
      - pkg: {{ mariadb_galera_server.package }}
  cmd.run:
    - onlyif: mysql -e 'select 1' -pchange_me
    - watch:
      - service: {{ mariadb_galera_server.package }}
    - name: mysql -e "grant all privileges on *.* to 'initialization_user'@'localhost' identified by 'change_me'" -pchange_me && mysql -e "update user set password = '{{ salt['pillar.get']('mariadb_galera_server:users:present:root:password_hash') }}' where user = 'root'" -pchange_me mysql && mysql -e "flush privileges" -pchange_me mysql

# Point the minion at this file, useful for running mysql_user and mysql_grant states
/etc/salt/minion.d/75_mysql_defaults.conf:
  file.managed:
    - source: salt://mariadb-galera-server/files/75_mysql_defaults.conf


# Error log setting moved to my.cnf so it may be overridden reliably in a conf.d .cnf file.
# Not non-debian friendly
/etc/mysql/conf.d/mysqld_safe_syslog.cnf:
  file.absent

