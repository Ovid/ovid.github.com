-- Revert ovid:data/why-is-perl-not-putting-moose-in-the-core to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'why-is-perl-not-putting-moose-in-the-core' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
