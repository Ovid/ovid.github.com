-- Revert ovid:data/why-we-dont-read-the-news to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'why-we-dont-read-the-news' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
