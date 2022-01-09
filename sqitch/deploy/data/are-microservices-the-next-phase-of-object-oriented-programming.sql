-- Deploy ovid:data/are-microservices-the-next-phase-of-object-oriented-programming to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Are Microservices the Next Phase of Object-Oriented Programming?',
           'are-microservices-the-next-phase-of-object-oriented-programming',
           'Modern object-oriented programming is a far cry from what Dr. Alan Kay, the inventor of the term, intended. Are microservices the closer?',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
