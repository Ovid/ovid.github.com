-- Revert ovid:data/being-a-keynote-speaker to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'being-a-keynote-speaker' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
