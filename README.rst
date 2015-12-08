=====================
mariadb-galera-server
=====================

The mariadb-galera-server formula and pillar data may be used to bring up a new mariadb galera cluster of any size in a matter of minutes.  Additionally, the users.sls state file may be used to manage users and grants on any MySQL-like database server.

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

Available states
================

.. contents::
    :local:

``mariadb-galera-server``
-------------------------
The main entry point, including all of the necessary state files to get a new mariadb galera member joined to the cluster.  It is also capable of bringing up the 'primary' node.  Outside of user management which are run separately, this is the only sls file that is typically every called.

``config``
----------
Creates a basic my.cnf file and more importantly, manages /etc/mysql/conf.d/galera_cluster.cnf, which includes the wsrep settings and any node-specific settings that either extend or override the my.cnf file.

``install``
-----------
Installs mariadb-galera-server, instructs salt to use the debian-sys-maint account for user management, and ensures the service is running.

``performance``
---------------
Linux-specific performance tuning settings, currently just vm.swappiness, which may be overridden in the pillar data.

``pre_requisites``
------------------
Installs a number of prerequisites, such as rsync.

``ssl``
-------
Installs the certificate and key used by galera.  The key and cert are manually created and stored in pillar.

``users``
---------
User management.  Typically called manually, or cron'd usually on just a single cluster node where /etc/mysql/debian.cnf has credentials stored.  Adds, updates and removes users, as well as maintains password hashes and an arbitrary number of grants.

General Information and Tips
============================

+ A cluster should always have at least three members to avoid 'split brain' conditions.

  + If a split brain condition does occur, it may be necessary to set one node as primary like so:  set global wsrep_provider_options="pc.bootstrap=1";

+ 'select 1 from dual;' may be used to verify node health.
+ It is possible to determine the cluster member count with this query: show status like 'wsrep_cluster_size%';
+ The my.cnf that is part of this formula is very basic.  mysqld pillar settings may override settings in the my.cnf, such as innodb_buffer_pool_size, etc.  These settings are all placed in /etc/mysql/conf.d/galera_cluster.cnf.
+ Cluster members communicate over ssl, aside from rsyncing using a custom certificate and key that must be generated and added to the pillar data.
+ Nodes are ssl-enabled for client-server communication, using the snakeoil certificate/key.  If verifying identity is important, using the snakeoil key pair is discouraged.
+ mariadb will not be restarted by any of the states in this formula, unless galera_cluster.cnf is created, typically only occurring at initial install time.

Getting Started
===============

+ Bring up any instances that will be part of the cluster, with base installs.
+ Make sure all cluster members have resolvable DNS records (e.g. dig mariadb2).  In a test environment, installing dnsutils and dnsmasq may be helpful.
+ Update pillar data, setting passwords, a new wsrep key pair, and setting the cluster name.  To generate a key pair:

::

  openssl genrsa -out key.pem 2048
  openssl req -new -key key.pem -out cert_req.csr
  openssl x509 -req -in cert_req.csr -signkey key.pem -out cert.pem

+ Add the official mariadb sources to all cluster members, see the mariadb downloads page if not using Ubuntu wily:

::

  sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
  sudo add-apt-repository 'deb [arch=amd64,i386] http://mirrors.syringanetworks.net/mariadb/repo/10.0/ubuntu wily main'
  sudo apt-get update

+ Run the states on the first member, which will eventually become the donor, e.g.:

::

  root@mariadb1:/# salt-call state.sls mariadb-galera-server -l debug
  root@mariadb1:/# salt-call state.sls mariadb-galera-server.users -l debug

+ From the first member node, copy /etc/mysql/debian.cnf to additional cluster members:

::

  sudo mkdir -p /etc/mysql
  sudo mv /tmp/debian.cnf /etc/mysql # Assumes a current copy of the debian.cnf file resides in /tmp
  sudo chown -R root.root /etc/mysql/
  sudo chmod 600 /etc/mysql/debian.cnf

.. note::
   This formula uses the debian-sys-maint account, the credentials are stored in the debian.cnf file.  Distributing it
   to all cluster members is necessary for this account to function properly.

+ Run the states on additional cluster members, for example:

::

  root@mariadb2:/# salt-call state.sls mariadb-galera-server -l debug
  root@mariadb3:/# salt-call state.sls mariadb-galera-server -l debug
  root@mariadb4:/# salt-call state.sls mariadb-galera-server -l debug


ToDo / Known Issues
===================
+ Add support for non-Debian-based distributions.
+ Only short hostnames are presently used, having the option to use the fqdn may be a future enhancement.

License
=======

Apache License, version 2.0.  Please see LICENSE.
