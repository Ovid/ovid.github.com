-- Revert ovid:data/my-ai-life-simulator to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'my-ai-life-simulator' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
