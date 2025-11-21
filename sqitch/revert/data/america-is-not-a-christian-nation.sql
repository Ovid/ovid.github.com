-- Revert ovid:data/america-is-not-a-christian-nation to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'america-is-not-a-christian-nation' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
