-- Revert ovid:data/moose-has-a-problem to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'moose-has-a-problem' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
