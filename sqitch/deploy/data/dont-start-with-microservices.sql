-- Deploy ovid:data/dont-start-with-microservices to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Don''t Start with Microservices',
           'dont-start-with-microservices',
           'There are many mistakes people make with microservices. Starting with them is a big one.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
