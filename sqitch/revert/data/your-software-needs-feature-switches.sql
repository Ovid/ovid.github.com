-- Revert ovid:data/your-software-needs-feature-switches to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'feature-switch-best-practices' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
