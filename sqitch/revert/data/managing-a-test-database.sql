-- Revert ovid:data/managing-a-test-database to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'managing-a-test-database' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
