-- Revert ovid:data/prompt-engineering-is-not-dead to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'prompt-engineering-is-not-dead' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
