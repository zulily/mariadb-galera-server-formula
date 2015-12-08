include:
  - mariadb-galera-server.prerequisites
  - mariadb-galera-server.performance
  - mariadb-galera-server.install
  - mariadb-galera-server.ssl
  - mariadb-galera-server.config
# User management is most reliable when called separately with state.sls
#{% if salt['pillar.get']('mariadb_galera_server:settings:members:' + grains['host'] + ':first_member', False) %}
#  - mariadb-galera-server.users # only run users.sls on-demand or for an install on the first master when it is not a rebuild
#{% endif %}
