USE transactions;

SET autocommit = 0;
SET GLOBAL innodb_status_output = ON;
SET GLOBAL innodb_status_output_locks = ON;

SHOW ENGINE innodb status;

SELECT @@transaction_isolation;

########################
# Dirty reads
SET GLOBAL TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

/* Query 1 */
SELECT age
FROM users
WHERE id = 1;
/* will read 20 */

/* Query 3 */
SELECT age
FROM users
WHERE id = 1;
/* will read 21, but should read 20 */
########################


########################
# Lost updates
SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT @@transaction_isolation;

/* Query 1 */
START TRANSACTION;
SELECT @age := age
FROM users
WHERE id = 1;

/* Query 3 */
SET @age = @age + 10;

/* Query 5 */
UPDATE users
SET age = @age
WHERE id = 1;
COMMIT;
/* will write 30 */
########################


########################
# Non-repeatable reads
SET GLOBAL TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT @@transaction_isolation;

START TRANSACTION;
/* Query 1 */
SELECT *
FROM users
WHERE id = 1;
/* will read 20 */

/* Query 3 */
SELECT *
FROM users
WHERE id = 1;
/* will read 21, but should read 20 */
COMMIT;
########################


########################
# Phantom reads
SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT @@transaction_isolation;

START TRANSACTION;
/* Query 1 */
SELECT *
FROM users
WHERE age BETWEEN 10 AND 30;

/* Query 3 */
SELECT *
FROM users
WHERE age BETWEEN 10 AND 30;
COMMIT;
########################


########################
# Serialization anomaly
SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT @@transaction_isolation;

START TRANSACTION;
/* Query 1 */
SELECT *
FROM users;

/* Query 3 */
SELECT @sum := sum(age)
FROM users;
/* will return 45 */

/* Query 5 */
INSERT INTO users (name, age) VALUES ('users', @sum);

COMMIT;
