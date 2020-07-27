-- Revert ovid:data/using-immutable-datetime-objects-with-dbixclass to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'using-immutable-datetime-objects-with-dbixclass' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
