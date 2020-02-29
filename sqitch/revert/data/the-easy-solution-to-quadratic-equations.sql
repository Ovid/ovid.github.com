-- Revert ovid:data/the-easy-solution-to-quadratic-equations to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'the-easy-solution-to-quadratic-equations' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
