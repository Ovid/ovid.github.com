-- Revert ovid:data/language-design-consistency to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'language-design-consistency' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
