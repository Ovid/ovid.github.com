-- Revert ovid:data/a-geodetic-refutation-of-flat-earth-theory to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'a-geodetic-refutation-of-flat-earth-theory' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
