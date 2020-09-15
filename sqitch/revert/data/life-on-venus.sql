-- Revert ovid:data/life-on-venus to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'life-on-venus' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
