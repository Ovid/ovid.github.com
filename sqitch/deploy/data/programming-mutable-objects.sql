-- Deploy ovid:data/programming-mutable-objects to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Programming Mutable Objects',
           'programming-mutable-objects',
           'I''ve often noted that many objections to object-oriented programming go away if the objects are immutable. But sometimes, you want them to be mutable.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
