-- Revert ovid:data/resigning-from-the-perl-foundation to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'resigning-from-the-perl-foundation' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
