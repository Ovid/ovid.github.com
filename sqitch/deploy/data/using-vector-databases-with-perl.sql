-- Deploy ovid:data/using-vector-databases-with-perl to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Using Vector Databases with Perl',
           'using-vector-databases-with-perl',
           'Vector databases are amazing, but there are few options with Perl. If you use PostgreSQL, now you have one.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
