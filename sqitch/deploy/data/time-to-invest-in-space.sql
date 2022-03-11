-- Deploy ovid:data/time-to-invest-in-space to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Time to Invest in Space?',
           'time-to-invest-in-space',
           'The nature of the nascent space industry is changing rapidly. The next decade is going to see tremendous changes.''',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
