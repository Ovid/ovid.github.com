-- Revert ovid:data/my-21-weddings to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'my-21-weddings' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
