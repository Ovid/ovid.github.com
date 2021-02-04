-- Deploy ovid:data/managing-a-test-database to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Managing a Test Database',
           'managing-a-test-database',
           'It''s easy to get test databases wrong. Here''s a nasty hack I did for a software test to make it easier to get the test database right.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
