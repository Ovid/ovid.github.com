-- Deploy ovid:data/what-to-know-before-debating-type-systems to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'What to Know Before Debating Type Systems ',
           'what-to-know-before-debating-type-systems',
           'I hate discussing type systems with people, so let this be a lesson for you.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
