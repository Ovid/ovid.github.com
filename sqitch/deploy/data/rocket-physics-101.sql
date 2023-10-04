-- Deploy ovid:data/rocket-physics-101 to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Rocket Physics 101',
           'rocket-physics-101',
           'Want to learn the basics of how rockets work?',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
