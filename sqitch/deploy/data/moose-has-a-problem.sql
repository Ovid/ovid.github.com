-- Deploy ovid:data/moose-has-a-problem to sqlite

BEGIN;

    INSERT INTO articles (title, slug, article_type_id, sort_order)
         VALUES (
           'Moose "has" a Problem',
           'moose-has-a-problem',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
