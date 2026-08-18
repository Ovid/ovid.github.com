-- Revert ovid:data/ai-didnt-break-copyright-it-exposed-it to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'ai-didnt-break-copyright-it-exposed-it' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
