-- Deploy ovid:data/naming-and-object-oriented-code to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Naming and Object Oriented Code',
           'naming-and-object-oriented-code',
           'I recently had an issue in a code review where developers disagreed about naming, but it was a subtle trap.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
