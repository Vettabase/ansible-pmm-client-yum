# ansible-pmm-client-yum
Ansible role to manage PMM Client on RHEL.


## Requisites

yum package manager is assumed. This role was initially developed for
Red Hat Enterprise Linux Server release 7.9 (Maipo).

Ansible version: 2.9.


## Configuration

These variables should be shared between this role and PMM Server role. Specify them at group or host level.

- `pmm_host`: PMM hostname/IP.
- `pmm_port`: PMM port. Default: '443'.
- `pmm_user`: PMM user.
- `pmm_password`: PMM password.

Role variables.

- `mariadb_user`: User that runs MariaDB queries.
- `mariadb_password`: Password for MariaDB user.
- `pmm_client_version`: Version of the pmm2-client to install. Upgrade or downgrade may be done when the role is applied. Default: 'latest'.
- `pmm_client_username`: MariaDB username used by PMM agent.
- `pmm_client_password`: MariaDB password used by PMM agent.
- `pmm_client_query_source`: 'slowlog', 'perfschema', 'none'. Recommended: 'slowlog'. Default: 'none'.
- `pmm_client_monitoring_mode`: 'push', 'pull', 'auto'. Default: 'push'.


These variables should be set at group or host level.

- `percona_release_version`: Version of percona-release to install. Upgrade or downgrade may be done when the role is applied. You may use other Percona software (like Percona Toolkit or Xtrabackup), so this variable should be available to all roles. Default: 'latest'.
- `environment`: This helps categorise each node in the PMM interface.
- `cluster_name`: This helps categorise each node in the PMM interface.
- `replication_set_name`: This helps categorise each node in the PMM interface.


## Copyright and License

Copyright  2021  Vettabase Ltd

License: BSD 3 (BSD-New).

Developed and maintained by Vettabase Ltd:

https://vettabase.com

Contributions are welcome.

