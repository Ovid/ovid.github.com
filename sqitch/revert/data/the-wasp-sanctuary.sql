-- Revert ovid:data/the-wasp-sanctuary to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'the-wasp-sanctuary' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
