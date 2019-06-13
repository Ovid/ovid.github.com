-- Deploy ovid:ddl/articles to sqlite

BEGIN;

    CREATE TABLE articles (
        article_id INTEGER PRIMARY KEY,
        title      VARCHAR(100) NOT NULL,
        slug       VARCHAR(100) NOT NULL,
        directory  VARCHAR(200) NOT NULL,
        created    TEXT         NOT NULL
    );

COMMIT;
