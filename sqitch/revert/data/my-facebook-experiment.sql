-- Revert ovid:data/my-facebook-experiment to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'my-facebook-experiment' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
