-- Revert ovid:data/understanding-class-inheritance to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'understanding-class-inheritance' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
