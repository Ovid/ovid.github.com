-- Revert ovid:data/common-problems-in-object-oriented-code to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'common-problems-in-object-oriented-code' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
