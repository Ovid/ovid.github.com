-- Revert ovid:data/is-math-discovered-or-invented to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'is-math-discovered-or-invented' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
