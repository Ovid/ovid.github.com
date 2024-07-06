-- Revert ovid:data/an-openai-chatbot-in-perl to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'an-openai-chatbot-in-perl' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
