-- Revert ovid:data/how-i-got-caught-in-high-school to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'how-i-got-caught-in-high-school' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
