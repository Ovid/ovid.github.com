-- Revert ovid:data/coronavirus-fake-news to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'coronavirus-fake-news' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
