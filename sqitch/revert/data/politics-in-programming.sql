-- Revert ovid:data/politics-in-programming to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'politics-in-programming' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
