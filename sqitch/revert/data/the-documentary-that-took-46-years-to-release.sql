-- Revert ovid:data/the-documentary-that-took-46-years-to-release to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'the-documentary-that-took-46-years-to-release' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
