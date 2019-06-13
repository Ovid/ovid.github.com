-- Revert ovid:data/initial_articles from sqlite

BEGIN;

    DELETE FROM articles;

COMMIT;
