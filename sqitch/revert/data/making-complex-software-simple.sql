-- Revert ovid:data/making-complex-software-simple to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'making-complex-software-simple' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
