-- Revert ovid:data/paad-v2-is-released to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'paad-v2-is-released' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
