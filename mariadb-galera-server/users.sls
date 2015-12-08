{# Ugly, but there really is no other simple way to create user
   accounts on the first run of this formula.  If adding a conf
   file to /etc/salt/minion.d (75_mysql_defaults.conf in this case),
   the settings only make it to __opts__ for the next job id.
#}
{% set first_run = False %}
{% if not salt['config.get']('mysql.default_file', False) and salt['cmd.run']('test -e /etc/mysql/debian.cnf') %}
  {% set first_run = True %}
{% endif %}

{#  Only create user accounts if this is not the initial install or if this is the first
    cluster member, according to pillar data.

    !! Need to update this to handle the case where the first_member is getting
       rebuilt !!
#}
{%- if not first_run or salt['pillar.get']('mariadb_galera_server:settings:members:' + grains['host'] + ':first_member', False) -%}

{% for user in salt['pillar.get']('mariadb_galera_server:users:present', None).keys() %}
{%- set grant_count = [ 1 ] -%}
# {{ user }} - user must be present, set grants as necessary
mariadb_galera_server_user_{{ user }}:
  {%- for host in salt['pillar.get']('mariadb_galera_server:users:present:' + user + ':hosts') %}
  mysql_user.present:
    - name: {{ user }}
      {%- if first_run %}
    - connection_user: initialization_user
    - connection_pass: change_me
      {%- endif %}
    - password_hash: "{{ salt['pillar.get']('mariadb_galera_server:users:present:' + user + ':password_hash') }}"
    - host: {{ host }}

    {% for grant in salt['pillar.get']('mariadb_galera_server:users:present:' + user + ':grants', []) %}

mariadb_galera_server_grant_{{ user }}_{{ grant_count|length }}:
  mysql_grants.present:
      {%- if first_run %}
    - connection_user: initialization_user
    - connection_pass: change_me
      {%- endif %}
    - host: {{ host }}
    - user: {{ user }}
    - grant: {{ grant['priv_type'] }}
    - database: {{ grant['database'] }}
      {%- do grant_count.append(1) %}
    {%- endfor %}
  {%- endfor %}

{% endfor %}

{% for user in salt['pillar.get']('mariadb_galera_server:users:absent', []) %}
# {{ user }} - set for removal
mariadb_absent_{{ user }}:
  mysql_user.absent:
    - name: {{ user }}
      {%- if first_run %}
    - connection_user: initialization_user
    - connection_pass: change_me
      {%- endif %}
{% endfor %}

{%- endif %}
