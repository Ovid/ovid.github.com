-- Revert ovid:data/work-from-home-effectively to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'work-from-home-effectively' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
