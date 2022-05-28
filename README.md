# TASK
Bring up percona and postgre and create a table.

By changing isolation levels and making parallel queries reproduce the main problems of parallel access: lost update, dirty read, non-repeatable read, phantom read

[WIKI: Isolation database systems](https://en.wikipedia.org/wiki/Isolation_(database_systems))

# SETUP
```shell
# Run containert
$ make up

# Go into MySQL container
$ make mysql

# Go into Postgres container
$ make postgres
```
# Queries
## MySQL
```mysql
# SESSION 1
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

```
```mysql
# SESSION 2
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
```

## Postgres
```postgresql
-- SESSION 1
\set AUTOCOMMIT off;

----------------------------------------------------
-- Dirty reads
START TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT current_setting('transaction_isolation');

/* Query 1 */
SELECT age
FROM transactions.public.users
WHERE id = 1;
/* will read 20 */

/* Query 3 */
SELECT age
FROM transactions.public.users
WHERE id = 1;
/* will read 20, all good */
----------------------------------------------------


----------------------------------------------------
-- Lost updates
START TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT current_setting('transaction_isolation');

START TRANSACTION;
/* Query 1 */
SELECT age
FROM transactions.public.users
WHERE id = 1;

/* Query 3 with commit */
UPDATE transactions.public.users
SET age = (SELECT age FROM transactions.public.users WHERE id = 1) + 1
WHERE id = 1; -- we read 20 before
COMMIT;
/* will write 21 */
----------------------------------------------------


----------------------------------------------------
-- Non-repeatable reads
START TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT current_setting('transaction_isolation');

START TRANSACTION;
/* Query 1 */
SELECT *
FROM transactions.public.users
WHERE id = 1;
/* will read 20 */

/* Query 3 */
SELECT *
FROM transactions.public.users
WHERE id = 1;
/* will read 21, but should read 20 */
COMMIT;
----------------------------------------------------


----------------------------------------------------
-- Phantom reads
START TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT current_setting('transaction_isolation');

START TRANSACTION;
/* Query 1 */
SELECT *
FROM transactions.public.users
WHERE age BETWEEN 10 AND 30;

/* Query 3 */
SELECT *
FROM transactions.public.users
WHERE age BETWEEN 10 AND 30;
COMMIT;
----------------------------------------------------


----------------------------------------------------
-- Serialization anomaly
START TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT current_setting('transaction_isolation');

/* Query 1 */
SELECT *
FROM transactions.public.users;

/* Query 3 */
SELECT sum(age)
FROM transactions.public.users;
/* will return 45 */

/* Query 5 with commit */
INSERT INTO transactions.public.users (id, name, age)
SELECT nextval('user_sequence'), 'users', sum(age) FROM transactions.public.users;
COMMIT;
```
```postgresql
-- SESSION 2
\set AUTOCOMMIT off;

----------------------------------------------------
-- Dirty reads
START TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT current_setting('transaction_isolation');

/* Query 2 */
UPDATE transactions.public.users
SET age = 21
WHERE id = 1;
/* No commit here */

ROLLBACK;
/* lock-based DIRTY READ */
----------------------------------------------------


----------------------------------------------------
-- Lost updates
START TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT current_setting('transaction_isolation');

START TRANSACTION;
/* Query 2 */
SELECT age
FROM transactions.public.users
WHERE id = 1;

/* Query 4 with commit */
UPDATE transactions.public.users
SET age = 20 + 1
WHERE id = 1; -- we read 20 before
COMMIT;
/* will write 21, but should write 22 */
----------------------------------------------------


----------------------------------------------------
-- Non-repeatable reads
START TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT current_setting('transaction_isolation');

/* Query 2 */
UPDATE transactions.public.users
SET age = 21
WHERE id = 1;
COMMIT;
----------------------------------------------------


----------------------------------------------------
-- Phantom reads
START TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT current_setting('transaction_isolation');

/* Query 2 */
INSERT INTO transactions.public.users(id, name, age)
VALUES (3, 'Bob', 27);
COMMIT;
----------------------------------------------------


----------------------------------------------------
-- Serialization anomaly
START TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT current_setting('transaction_isolation');

/* Query 2 */
SELECT *
FROM transactions.public.users;

/* Query 4 */
SELECT sum(age)
FROM transactions.public.users;
/* will return 45 */

/* Query 6 with commit */
INSERT INTO transactions.public.users (id, name, age)
SELECT nextval('user_sequence'), 'users', sum(age) FROM transactions.public.users;
COMMIT;
```

# Result
## MySQL (percona)
| Isolation level\Read phenomena | Dirty reads | Lost updates | Non-repeatable reads | Phantom reads | Serialization anomaly |
|:-------------------------------|:-----------:|:------------:|:--------------------:|:-------------:|:---------------------:|
| Read Uncommitted               |      +      |      +       |          +           |       +       |           +           |
| Read Committed                 |      -      |      +       |          +           |       -       |           +           |
| Repeatable Read                |      -      |      +       |          +           |       -       |           +           |
| Serializable                   |      -      |      -       |          -           |       -       |           -           |
* `+` means can be reproduced, `-` means can't be reproduced
* You will never found phantoms on InnoDB mysql with read committed or more restricted isolation level. It is explained on documentation:
REPEATABLE READ: For consistent reads, there is an important difference from the READ COMMITTED isolation level: All consistent **reads within the same transaction read the snapshot established by the first read**. This convention means that if you issue several plain (nonlocking) SELECT statements within the same transaction, these SELECT statements are consistent also with respect to each other. See Section 13.6.8.2, “Consistent Nonlocking Reads”.
But you can't also found phantoms in read committed isolation level: This is necessary because “phantom rows” must be blocked for MySQL replication and recovery to work.

## PostgreSQL
[The SQL standard defines one additional level, READ UNCOMMITTED. In PostgreSQL READ UNCOMMITTED is treated as READ COMMITTED.](https://www.postgresql.org/docs/current/sql-set-transaction.html)

| Isolation level\Read phenomena | Dirty reads | Lost updates | Non-repeatable reads | Phantom reads | Serialization anomaly |
|:-------------------------------|:-----------:|:------------:|:--------------------:|:-------------:|:---------------------:|
| ~~Read Uncommitted~~           |     n/a     |     n/a      |         n/a          |      n/a      |          n/a          |
| Read Committed                 |      -      |      +       |          +           |       +       |           +           |
| Repeatable Read                |      -      |      +       |          -           |       -       |           +           |
| Serializable                   |      -      |      -       |          -           |       -       |           -           |
* `+` means can be reproduced, `-` means can't be reproduced
