-- Revert ovid:data/programming-mutable-objects to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'programming-mutable-objects' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
