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
