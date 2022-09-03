-- Revert ovid:data/naming-and-object-oriented-code to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'naming-and-object-oriented-code' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
