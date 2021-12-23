-- Deploy ovid:data/how-i-got-caught-in-high-school to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'How I Got Caught in High School',
           'how-i-got-caught-in-high-school',
           'Teenages are stupid. I was no exception. I once got caught breaking into my high school.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
