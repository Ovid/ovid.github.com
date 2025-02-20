-- Revert ovid:data/getting-a-job-offer-in-another-country to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'getting-a-job-offer-in-another-country' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
