-- Revert ovid:data/ovid-in-the-trenches to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'ovid-in-the-trenches' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
