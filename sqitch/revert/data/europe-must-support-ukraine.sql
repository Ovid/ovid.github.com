-- Revert ovid:data/europe-must-support-ukraine to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'europe-must-support-ukraine' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
