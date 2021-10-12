-- Deploy ovid:data/jeff-bezos-1000-problems to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'What''s Wrong with Blue Origin?',
           'jeff-bezos-1000-problems',
           'The depth of problems that plague Blue Origin are astonishing.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
