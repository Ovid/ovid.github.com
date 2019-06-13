-- Revert ovid:ddl/articles from sqlite

BEGIN;

    DROP TABLE articles;

COMMIT;
