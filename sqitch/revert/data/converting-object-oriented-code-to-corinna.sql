-- Revert ovid:data/converting-object-oriented-code-to-corinna to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'converting-object-oriented-code-to-corinna' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
