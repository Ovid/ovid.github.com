-- Revert ovid:articles_types/description from sqlite

BEGIN;

--
-- Creating our new table
-- Manually change the table here, such as adding a new column
-- 
CREATE TABLE article_types_1582962596 (
        article_type_id INTEGER PRIMARY KEY,
        name            VARCHAR(200) NOT NULL UNIQUE,
        type            VARCHAR(200) NOT NULL UNIQUE,
        directory       VARCHAR(200) NOT NULL UNIQUE
    );


--
-- Manually alter each of these insert statements as needed
--
INSERT INTO article_types_1582962596 VALUES(1,'Articles','article','articles');
INSERT INTO article_types_1582962596 VALUES(2,'Blog Entries','blog','blog');


DROP TABLE article_types;
ALTER TABLE article_types_1582962596 RENAME TO article_types;

--
-- If there are any existing triggers, views, or indexes which need to be recreated,
-- do so here
--

COMMIT;

