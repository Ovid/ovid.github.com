-- Revert ovid:data/escape-adventurs-in-ai-gaming to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'escape-adventurs-in-ai-gaming' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
