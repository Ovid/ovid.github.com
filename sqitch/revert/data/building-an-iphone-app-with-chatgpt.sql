-- Revert ovid:data/building-an-iphone-app-with-chatgpt to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'building-an-iphone-app-with-chatgpt' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
