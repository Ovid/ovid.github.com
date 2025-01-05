-- Revert ovid:data/why-black-people-hate-your-dreads to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'why-black-people-hate-your-dreads' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
