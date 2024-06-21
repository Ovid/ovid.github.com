-- Revert ovid:data/claude-sonnet-35-beats-chatgpt-40 to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'claude-sonnet-35-beats-chatgpt-40' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
