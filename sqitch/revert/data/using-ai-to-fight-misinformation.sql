-- Revert ovid:data/using-ai-to-fight-misinformation to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'using-ai-to-fight-misinformation' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
