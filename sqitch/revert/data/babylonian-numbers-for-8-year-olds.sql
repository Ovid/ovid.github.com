-- Revert ovid:data/babylonian-numbers-for-8-year-olds to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'babylonian-numbers-for-8-year-olds' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
