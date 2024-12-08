-- Revert ovid:data/a-review-of-openais-new-chatgpt-o1 to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'a-review-of-openais-new-chatgpt-o1' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
