-- Revert ovid:data/dont-defund-the-police to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'dont-defund-the-police' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
