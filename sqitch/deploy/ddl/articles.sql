-- Deploy ovid:ddl/articles to sqlite

BEGIN;

    CREATE TABLE articles (
        article_id INTEGER PRIMARY KEY,
        name       VARCHAR(100) NOT NULL,
        slug       VARCHAR(100) NOT NULL,
        created    TEXT NOT NULL
    );

COMMIT;
