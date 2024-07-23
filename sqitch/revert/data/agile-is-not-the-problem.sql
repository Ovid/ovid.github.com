-- Revert ovid:data/agile-is-not-the-problem to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'agile-is-not-the-problem' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
