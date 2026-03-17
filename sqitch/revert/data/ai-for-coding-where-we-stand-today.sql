-- Revert ovid:data/ai-for-coding-where-we-stand-today to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'why-i-am-no-longer-reading-the-ais-code' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
