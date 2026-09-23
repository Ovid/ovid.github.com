-- Revert ovid:data/paads-test-roadmap-instant-test-suites to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'paads-test-roadmap-instant-test-suites' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
