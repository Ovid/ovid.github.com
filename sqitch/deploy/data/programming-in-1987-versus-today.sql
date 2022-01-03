-- Deploy ovid:data/programming-in-1987-versus-today to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Programming in 1987 Versus Today',
           'programming-in-1987-versus-today',
           'Many developers today have no idea what programming was like in the 80s.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
