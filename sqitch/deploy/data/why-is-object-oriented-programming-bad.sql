-- Deploy ovid:data/why-is-object-oriented-programming-bad to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Why is Object-Oriented Programming Bad?',
           'why-is-object-oriented-programming-bad',
           'You can find many articles explaining with OOP is bad. It''s not, but you need to understand the problems.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
