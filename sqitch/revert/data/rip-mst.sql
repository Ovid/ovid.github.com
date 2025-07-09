-- Revert ovid:data/rip-mst to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'rip-mst' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
