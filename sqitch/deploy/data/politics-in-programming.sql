-- Deploy ovid:data/politics-in-programming to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Politics in Programming',
           'politics-in-programming',
           'Designing the Corinna OO system for Perl has been as much a political exercise as a technical one. This has been a good thing.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
