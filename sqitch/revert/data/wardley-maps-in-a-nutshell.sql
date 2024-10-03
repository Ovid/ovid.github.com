-- Revert ovid:data/wardley-maps-in-a-nutshell to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'wardley-maps-in-a-nutshell' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
