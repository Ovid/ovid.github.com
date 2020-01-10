-- Revert ovid:data/database-design-standards to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'database-design-standards' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
