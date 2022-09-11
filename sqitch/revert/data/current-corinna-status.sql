-- Revert ovid:data/current-corinna-status to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'current-corinna-status' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
