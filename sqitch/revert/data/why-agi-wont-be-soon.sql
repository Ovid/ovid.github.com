-- Revert ovid:data/why-agi-wont-be-soon to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'why-agi-wont-be-soon' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
