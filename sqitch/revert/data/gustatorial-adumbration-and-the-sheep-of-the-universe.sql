-- Revert ovid:data/gustatorial-adumbration-and-the-sheep-of-the-universe to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'gustatorial-adumbration-and-the-sheep-of-the-universe' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
