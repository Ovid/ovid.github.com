-- Revert ovid:data/all-around-the-world-celebrating-ten-years to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'all-around-the-world-celebrating-ten-years' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
