-- Deploy ovid:data/understanding-class-inheritance to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Understanding Class Inheritance',
           'understanding-class-inheritance',
           'Inheritance has been problematic in object-oriented programming for over five decades. We will explore why.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
