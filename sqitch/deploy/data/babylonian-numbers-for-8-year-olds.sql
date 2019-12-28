-- Deploy ovid:data/babylonian-numbers-for-8-year-olds to sqlite

BEGIN;

    INSERT INTO articles (title, slug, article_type_id, sort_order)
         VALUES (
           'Babylonian Numbers for 8-Year Olds',
           'babylonian-numbers-for-8-year-olds',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
