# ansible-pmm-client-yum

Ansible role to manage PMM Client on RHEL.


## Requisites

yum package manager is assumed. This role was initially developed for
Red Hat Enterprise Linux Server release 7.9 (Maipo).

Ansible version: 2.9.


## Variables

### Global variables

These variables should be shared between this role and PMM Server role. Specify them at group or host level.

- `pmm_server_host`: PMM hostname/IP.
- `pmm_server_port`: PMM port. Default: '443'.
- `pmm_server_user`: PMM user.
- `pmm__server_password`: PMM password.

### Role variables

These variables have defaults in `defaults/main.yml`. Make sure to override defaults as appropriate.

- `admin_mariadb_user`: User that sets up MariaDB access for `pmm_mariadb_username`.
- `admin_mariadb_password`: MariaDB password for `admin_mariadb_user`.
- `pmm_client_version`: Version of the pmm2-client to install. Upgrade or downgrade may be done when the role is applied. Default: 'latest'.
- `pmm_mariadb_username`: MariaDB username used by PMM agent to get MariaDB metrics.
- `pmm_mariadb_password`: MariaDB password for `pmm_mariadb_username`.
- `pmm_client_query_source`: 'slowlog', 'perfschema', 'none'. Recommended: 'slowlog'. Default: 'none'.
- `pmm_client_monitoring_mode`: 'push', 'pull', 'auto'. Default: 'push'.


### Group or host level

These variables are meant to be to set at group or host level, as each host or group may be configured differently.

- `percona_release_version`: Version of percona-release to install. Upgrade or downgrade may be done when the role is applied. You may use other Percona software (like Percona Toolkit or Xtrabackup), so this variable should be available to all roles. Default: 'latest'.
- `environment`: This helps categorise each node in the PMM interface.
- `cluster_name`: This helps categorise each node in the PMM interface.
- `replication_set_name`: This helps categorise each node in the PMM interface.

### Skip variables

- `skip_stored_procedures_test`: Skip stored procedures tests (default). Run tests after making changes to the stored procedures, or upgrading MariaDB, or changing relevant parts of its configuration.
- `skip_pmm_client_configure`: Skip configuration of the PMM Client after installing it. Useful if no change has to be made, because otherwise the mysql service would be stopped and restarted.


## Tags

Normal operations:

- `pmm`: Run this role and other PMM client & server roles that use this tag.
- `pmm-client`: Run this role and other PMM client roles that use this tag.
- `pmm-client-configure`: Reconfigure client and recreates services.
- `monitor-scripts-upgrade`: Add monitor-related scripts.
- `percona-release-upgrade`: Upgrade/downgrade the `percona-release` package. This operation is not included in `pmm-client`.

Validation (use these tags after making changes):

- `validate`: Validate this role and other roles that use this tag.
- `pmm-validate`: Validate this role and other PMM Server and Client roles that support this role.
- `pmm-client-validate`: Validate this role.


## Stored Procedures

This role adds some stored procedures, which are executed as `admin_mariadb_user`.

The procedures are located in the `vettabase` database. The tests (only run when
`stored_procedures_test=1`) are in `test_vettabase`.

```
format_name(name)
    Return the name quoted with backticks. If the name contains backticks,
    they are escaped. This is useful to include table names, column names,
    etc, in SQL statements, when they could be reserved words or include
    special characters.
    Return NULL if name is NULL.

format_account(user, host)
    Return a string representing an account, with the specified username
    and host properly quoted. Useful to include an account in SQL statements.
    Return NULL if any parameter is NULL.

account_exists(user, host)
    Return whether the specified account exists.
    Return NULL if any parameter is NULL.

void create_pmm_user(user, host, password)
    Create an account with all the permissions needed by PMM agent, and
    the permission to execute this procedure.
    If no password is specified, the account will use unix_socket for
    authentication, which means that the user should exist in Linux
    and can only login (without password) from the local system.
    If a password is specified and the account already exists, the
    password is changed.
    Return NULL if user or host is NULL.
```


## Examples

Validating changes to all PMM clients configuration:

```
ansible-playbook --check -t pmm-client-validate -l pmm_client -i mariadb mariadb.yml
```

Deploying PMM clients on a host group called `mariadb_development`:

```
ansible-playbook -t pmm-client -l mariadb_development -i mariadb mariadb.yml
```


## Copyright and License

Copyright  2021  Vettabase Ltd

License: BSD 3 (BSD-New).

Developed and maintained by Vettabase Ltd:

https://vettabase.com

Contributions are welcome.
