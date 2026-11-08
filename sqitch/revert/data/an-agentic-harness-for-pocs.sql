-- Revert ovid:data/an-agentic-harness-for-pocs to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'an-agentic-harness-for-pocs' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
