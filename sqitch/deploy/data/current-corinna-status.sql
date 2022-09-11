-- Deploy ovid:data/current-corinna-status to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Current Corinna Status',
           'current-corinna-status',
           'Demonstrating the current state of the Perl Corinna OOP project by implementing a simple cache',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
