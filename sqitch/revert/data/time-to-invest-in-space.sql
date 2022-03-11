-- Revert ovid:data/time-to-invest-in-space to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'time-to-invest-in-space' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
