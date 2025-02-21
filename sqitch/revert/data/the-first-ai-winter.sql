-- Revert ovid:data/the-first-ai-winter to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'the-first-ai-winter' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
