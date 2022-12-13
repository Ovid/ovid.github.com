-- Revert ovid:data/is-spacex-stumbling to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'is-spacex-stumbling' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
