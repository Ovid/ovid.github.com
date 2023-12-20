-- Deploy ovid:data/microservices-pros-and-cons to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Microservices Pros and Cons',
           'microservices-pros-and-cons',
           'Advocates and adversaries of microservices pitch their points of view. Let''s look at both.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
