-- Revert ovid:data/will-it-rain-tomorrow to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'will-it-rain-tomorrow' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
