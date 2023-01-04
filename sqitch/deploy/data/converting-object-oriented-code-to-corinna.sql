-- Deploy ovid:data/converting-object-oriented-code-to-corinna to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Converting Object-Oriented Code to Corinna',
           'converting-object-oriented-code-to-corinna',
           'I was recently humbled when I converted some code to Corinna and Corinna''s constraints showed the design flaws in my code.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
