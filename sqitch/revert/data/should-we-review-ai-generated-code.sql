-- Revert ovid:data/should-we-review-ai-generated-code to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'should-we-review-ai-generated-code' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
