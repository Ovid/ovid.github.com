-- Revert ovid:data/redefining-life-as-a-continuum to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'redefining-life-as-a-continuum' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
