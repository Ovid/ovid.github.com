-- Revert ovid:data/real-world-value-with-generative-ai to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'real-world-value-with-generative-ai' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
