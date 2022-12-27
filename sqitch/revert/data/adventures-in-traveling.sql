-- Revert ovid:data/adventures-in-traveling to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'adventures-in-traveling' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
