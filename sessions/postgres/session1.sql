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

/* Query 3 */
UPDATE transactions.public.users
SET age = 20 + 1
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
