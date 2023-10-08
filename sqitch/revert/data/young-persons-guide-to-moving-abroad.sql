-- Revert ovid:data/young-persons-guide-to-moving-abroad to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'young-persons-guide-to-moving-abroad' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
