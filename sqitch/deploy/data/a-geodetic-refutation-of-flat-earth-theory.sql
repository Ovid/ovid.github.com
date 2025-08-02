-- Deploy ovid:data/a-geodetic-refutation-of-flat-earth-theory to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'A Geodetic Refutation of Flat-Earth Theory',
           'a-geodetic-refutation-of-flat-earth-theory',
           'A Formal Refutation of âFlatâEarthâ Claims through the Lens of NegativeâCurvature Geodesy',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
