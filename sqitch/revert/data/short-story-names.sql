-- Revert ovid:data/short-story-names to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'short-story-names' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
