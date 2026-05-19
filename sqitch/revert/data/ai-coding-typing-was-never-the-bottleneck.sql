-- Revert ovid:data/ai-coding-typing-was-never-the-bottleneck to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'ai-coding-typing-was-never-the-bottleneck' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
