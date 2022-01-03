-- Revert ovid:data/programming-in-1987-versus-today to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'programming-in-1987-versus-today' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
