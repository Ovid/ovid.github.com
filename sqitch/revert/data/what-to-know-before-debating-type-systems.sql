-- Revert ovid:data/what-to-know-before-debating-type-systems to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'what-to-know-before-debating-type-systems' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
