-- Revert ovid:data/introducing-moosexextended-for-perl to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'introducing-moosexextended-for-perl' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
