vm.swappiness:
  sysctl.present:
    - value: {{ salt['pillar.get']('mariadb_galera_server:settings:performance:vm_swappiness', 0) }}
