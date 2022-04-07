-- Revert ovid:data/why-i-write to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'why-i-write' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
