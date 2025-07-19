-- Revert ovid:data/ai-today-is-like-the-early-internet to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'ai-today-is-like-the-early-internet' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
