CREATE TABLE transactions.public.users
(
    id   integer primary key,
    name varchar(20),
    age  integer
);

INSERT INTO transactions.public.users (id, name, age) VALUES
(1, 'Joe', 20),
(2, 'Jill', 25);
COMMIT;
