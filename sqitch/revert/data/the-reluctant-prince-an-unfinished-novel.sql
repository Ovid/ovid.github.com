-- Revert ovid:data/the-reluctant-prince-an-unfinished-novel to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'the-reluctant-prince-an-unfinished-novel' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
