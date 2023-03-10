-- Revert ovid:data/the-future-of-perl to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'the-future-of-perl' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
