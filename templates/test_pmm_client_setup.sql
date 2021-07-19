/*
    This file contains simple tests for the procedures created by
    pmm_client_setup.sql.
    The results are written into test_vettabase.test_results.
    When this file is run, the last resultsets are test results statistics.
*/


-- always show warnings
\W


-- always show warnings
\W


CREATE DATABASE IF NOT EXISTS test_vettabase;
USE test_vettabase;

DELIMITER ||


CREATE OR REPLACE TABLE test_results (
    id INTEGER UNSIGNED AUTO_INCREMENT,
    test_name VARCHAR(50) NOT NULL,
    is_correct BOOL NOT NULL CHECK (is_correct = FALSE OR is_correct = TRUE),
    got_result VARCHAR(100),
    expected_result VARCHAR(100),
    PRIMARY KEY (id),
    UNIQUE unq_test_name (test_name)
);

TRUNCATE TABLE test_results;


CREATE OR REPLACE PROCEDURE is_same(
        IN in_test_name VARCHAR(50),
        IN in_got_result VARCHAR(100),
        IN in_expected_result VARCHAR(100)
    )
    DETERMINISTIC
    CONTAINS SQL
    COMMENT 'Record weather a function returns the expected result'
BEGIN
    -- what we get is equal to what we expect,
    -- or both are NULL
    DECLARE v_is_correct BOOL DEFAULT in_got_result <=> in_expected_result;
    INSERT INTO test_vettabase.test_results (test_name, is_correct, got_result, expected_result)
        VALUES (in_test_name, v_is_correct, in_got_result, in_expected_result);
END;


CALL is_same('format_name 1', vettabase.format_name(NULL), NULL);
CALL is_same('format_name 2', vettabase.format_name(''), '``');
CALL is_same('format_name 3', vettabase.format_name('name'), '`name`');
CALL is_same('format_name 4', vettabase.format_name('a`b'), '`a``b`');


CALL is_same('format_account 1', vettabase.format_account(NULL, NULL),              NULL);
CALL is_same('format_account 2', vettabase.format_account(NULL, 'some_host'),       NULL);
CALL is_same('format_account 3', vettabase.format_account('a_user', NULL),          NULL);
CALL is_same('format_account 4', vettabase.format_account('a_user', 'some_host'),   '''a_user''@''some_host''');
CALL is_same('format_account 5', vettabase.format_account('a''user', 'some_host'),  '''a\\''user''@''some_host''');
CALL is_same('format_account 6', vettabase.format_account('a_user', 'some''host'),  '''a_user''@''some\\''host''');

CALL is_same('account_exists 1', vettabase.format_account(NULL, NULL),                  NULL);
CALL is_same('account_exists 2', vettabase.format_account(NULL, 'not_exists'),          NULL);
CALL is_same('account_exists 3', vettabase.format_account('not_exists', NULL),          NULL);
CALL is_same('account_exists 4', vettabase.format_account('not_exists', 'not_exists'),  '''not_exists''@''not_exists''');

-- MISSING:
-- * test account_exists() calls that should return TRUE
-- * create_pmm_user()


||
DELIMITER ;

DELIMITER ||

BEGIN NOT ATOMIC


-- show results statistics
SELECT IF(is_correct = TRUE, 'YES', 'NO') AS success, COUNT(*) AS `count` FROM test_results GROUP BY success;

-- show failed results
IF EXISTS (SELECT is_correct FROM test_results WHERE is_correct <> 1 LIMIT 1) THEN
    SELECT test_name AS `failed_test`, expected_result, got_result FROM test_results WHERE is_correct IS NOT TRUE;
END IF;


END;

||
DELIMITER ;
