-- Deploy ovid:data/short-story-names to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Short Story: "Names"',
           'short-story-names',
           'A short story I wrote a few years ago, playing around with first-person, non-linear storytelling.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
