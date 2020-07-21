-- Revert ovid:data/what-is-socialism to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'what-is-socialism' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
