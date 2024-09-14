-- Revert ovid:data/ai-generated-content-innovation-or-intellectual-theft to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'ai-generated-content-innovation-or-intellectual-theft' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
