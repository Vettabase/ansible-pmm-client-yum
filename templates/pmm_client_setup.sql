/*
    PROBLEM
    =======

    The person who applies the role may not have enough permissions to grant
    the PMM user the permissions it needs.


    SOLUTION
    ========

    Having certain MariaDB permissions is necessary to create the pmm user in MariaDB,
    thus it's necessary to run at least the PMM client initial installation.

    The role should be done by root the first time. It will create a procedure to setup
    the PMM user correctly, and will assign another user the EXECUTE permission (let's
    call them the "executer user").
    root will also execute the procedure.
    After that, anyone who can connect as the executer user will be able to run the
    procedure, creating / modifying / recreating the PMM user.
*/


-- always show warnings
\W


CREATE DATABASE IF NOT EXISTS vettabase;
USE vettabase;

DELIMITER ||


CREATE OR REPLACE FUNCTION format_name(
        p_name VARCHAR(64)
    )
    RETURNS VARCHAR(70)
    DETERMINISTIC
    CONTAINS SQL
    COMMENT 'Quote an SQL name so it can contain any special chat including backtick'
BEGIN
    RETURN CONCAT('`', REPLACE(p_name, '`', '``'), '`');
END;


CREATE OR REPLACE FUNCTION format_account(
        p_user VARCHAR(64),
        p_host VARCHAR(64)
    )
    RETURNS VARCHAR(140)
    DETERMINISTIC
    CONTAINS SQL
    COMMENT 'Quote an SQL account (user + host)'
BEGIN
    IF p_user IS NULL OR p_host IS NULL THEN
        RETURN NULL;
    ELSE
        RETURN CONCAT(QUOTE(p_user), '@', QUOTE(p_host));
    END IF;
END;


CREATE OR REPLACE FUNCTION account_exists(
        p_user VARCHAR(64),
        p_host VARCHAR(64)
    )
    RETURNS BOOL
    NOT DETERMINISTIC
    READS SQL DATA
    COMMENT 'Returns TRUE if the given account exists, FALSE otherwise'
BEGIN
    RETURN EXISTS (SELECT user FROM mysql.user WHERE user = p_user AND host = p_host);
END;


CREATE OR REPLACE PROCEDURE create_pmm_user(
            IN p_executer_user VARCHAR(64),
            IN p_executer_host VARCHAR(64),
            IN p_executer_password VARCHAR(64)
        )
        SQL SECURITY DEFINER
        NOT DETERMINISTIC
        MODIFIES SQL DATA
        COMMENT 'Create user for PMM agent, with proper privileges'
BEGIN
    -- user@host
    DECLARE v_executer_account VARCHAR(64) DEFAULT
        format_account(p_executer_user, p_executer_host);

    -- Validate input:
    -- specify p_executer_user, p_executer_host and p_executer_password
    -- or none of them.
    IF
        NOT (p_executer_user IS NULL AND p_executer_host IS NULL AND p_executer_password IS NULL)
        AND NOT (p_executer_user IS NOT NULL AND p_executer_host IS NOT NULL AND p_executer_password IS NOT NULL)
    THEN
        SIGNAL SQLSTATE '45000' SET
              MESSAGE_TEXT = 'Invalid input: specify all parameters or set them all to NULL'
            , MYSQL_ERRNO = 60000
        ;
    END IF;

    -- create executer if not exists, make sure the password is correct,
    -- and grant EXECUTE privilege on this procedure
    IF NOT account_exists(p_executer_user, p_executer_host) THEN
        EXECUTE IMMEDIATE CONCAT(
            'CREATE USER IF NOT EXISTS ', v_executer_account, ' IDENTIFIED BY ', p_executer_password, ';'
        );
    END IF;

    -- set password
    EXECUTE IMMEDIATE CONCAT(
        'SET PASSWORD FOR ', v_executer_account, ' = ', QUOTE(p_executer_password), ';'
    );

    -- grant permissions needed by PMM agent
    EXECUTE IMMEDIATE CONCAT(
        'CREATE USER ', v_executer_account,
            ' WITH MAX_USER_CONNECTIONS 10',
        ';'
    );
    EXECUTE IMMEDIATE CONCAT(
        'GRANT ',
                'SELECT, PROCESS, SUPER, REPLICATION CLIENT, RELOAD ',
            'ON *.* ',
            'TO ', v_executer_account,
        ';'
    );

    -- permission to run this procedure
    EXECUTE IMMEDIATE CONCAT(
        'GRANT EXECUTE ON vettabase.* TO ', v_executer_account, ';'
    );

    FLUSH PRIVILEGES;
END;


||
DELIMITER ;
