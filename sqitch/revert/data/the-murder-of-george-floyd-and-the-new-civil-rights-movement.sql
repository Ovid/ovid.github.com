-- Revert ovid:data/the-murder-of-george-floyd-and-the-new-civil-rights-movement to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'the-murder-of-george-floyd-and-the-new-civil-rights-movement' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
