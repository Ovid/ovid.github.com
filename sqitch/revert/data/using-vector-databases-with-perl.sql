-- Revert ovid:data/using-vector-databases-with-perl to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'using-vector-databases-with-perl' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
