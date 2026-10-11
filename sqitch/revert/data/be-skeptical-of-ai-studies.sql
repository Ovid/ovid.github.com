-- Revert ovid:data/be-skeptical-of-ai-studies to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'be-skeptical-of-ai-studies' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
