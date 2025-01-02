-- Revert ovid:data/the-new-terrorism-threat-in-the-usa to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'the-new-terrorism-threat-in-the-usa' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
