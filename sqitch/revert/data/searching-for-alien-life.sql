-- Revert ovid:data/searching-for-alien-life to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'searching-for-alien-life' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
