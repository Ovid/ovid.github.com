-- Deploy ovid:data/the-easy-solution-to-quadratic-equations to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'The Easy Solution to Quadratic Equations',
           'the-easy-solution-to-quadratic-equations',
           'The mathmetician Po-Shen Loh has created a much easier way to solve quadratic equations. Let''s take a look.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
