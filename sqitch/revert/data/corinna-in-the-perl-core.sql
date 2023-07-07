-- Revert ovid:data/corinna-in-the-perl-core to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'corinna-in-the-perl-core' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
