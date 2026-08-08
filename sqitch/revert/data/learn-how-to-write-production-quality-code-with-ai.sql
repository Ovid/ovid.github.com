-- Revert ovid:data/learn-how-to-write-production-quality-code-with-ai to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'learn-how-to-write-production-quality-code-with-ai' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
