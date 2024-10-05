-- Revert ovid:data/ai-for-accessibility to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'ai-for-accessibility' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
