-- Revert ovid:data/a-city-on-mars-review to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'a-city-on-mars-review' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
