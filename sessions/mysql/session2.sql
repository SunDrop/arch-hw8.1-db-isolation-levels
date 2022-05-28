USE transactions;

SET autocommit = 0;
SET GLOBAL innodb_status_output = ON;
SET GLOBAL innodb_status_output_locks = ON;

SHOW ENGINE innodb status;

########################
# Dirty reads
SET GLOBAL TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT @@transaction_isolation;

/* Query 2 */
UPDATE users SET age = 21 WHERE id = 1;
/* No commit here */

ROLLBACK; /* lock-based DIRTY READ */
########################

########################
# Lost updates
SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT @@transaction_isolation;

/* Query 2 */
START TRANSACTION;
SELECT @age := age FROM users WHERE id = 1;

/* Query 4 */
SET @age = @age + 20;

/* Query 6 */
UPDATE users SET age = @age WHERE id = 1;
COMMIT;
/* will write 40, but should write 50 */
########################


########################
# Non-repeatable reads
SET GLOBAL TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT @@transaction_isolation;

/* Query 2 */
UPDATE users SET age = 21 WHERE id = 1;
COMMIT;
########################


########################
# Phantom reads
SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT @@transaction_isolation;

/* Query 2 */
INSERT INTO users(id, name, age) VALUES (3, 'Bob', 27);
COMMIT;
########################


########################
# Serialization anomaly
SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT @@transaction_isolation;

START TRANSACTION;
/* Query 2 */
SELECT *
FROM users;

/* Query 4 */
SELECT @sum := sum(age)
FROM users;
/* will return 45 */

/* Query 5 */
INSERT INTO users (name, age) VALUES ('users', @sum);

COMMIT;
