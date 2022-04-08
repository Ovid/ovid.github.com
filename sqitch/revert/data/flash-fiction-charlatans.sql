-- Revert ovid:data/flash-fiction-charlatans to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'flash-fiction-charlatans' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
