-- Revert ovid:data/rocket-physics-101 to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'rocket-physics-101' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
