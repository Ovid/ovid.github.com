-- Revert ovid:data/why-you-will-stay-no-to-living-abroad to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'why-you-will-say-no-to-living-abroad' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
