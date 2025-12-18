-- Deploy ovid:data/real-world-value-with-generative-ai to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Real-World Value with Generative AI',
           'real-world-value-with-generative-ai',
           'Despite claims to the contrary, AI is generating strong real-world value and it is easy to demonstrate.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
