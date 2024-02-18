-- Revert ovid:data/will-you-lose-your-job-to-ai to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'will-you-lose-your-job-to-ai' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
