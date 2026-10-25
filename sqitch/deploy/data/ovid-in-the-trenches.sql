-- Deploy ovid:data/ovid-in-the-trenches to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Ovid in the Trenches',
           'ovid-in-the-trenches',
           'The new "trenches" articles will be shorter (maybe) articles focused exclusively on real-life situations. This is the first.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
