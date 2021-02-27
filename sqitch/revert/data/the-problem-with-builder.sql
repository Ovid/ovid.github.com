-- Revert ovid:data/the-problem-with-builder to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'the-problem-with-builder' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
