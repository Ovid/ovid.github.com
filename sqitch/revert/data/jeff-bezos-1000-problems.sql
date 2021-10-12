-- Revert ovid:data/jeff-bezos-1000-problems to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'jeff-bezos-1000-problems' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
