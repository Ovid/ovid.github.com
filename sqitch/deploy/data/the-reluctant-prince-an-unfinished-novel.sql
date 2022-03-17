-- Deploy ovid:data/the-reluctant-prince-an-unfinished-novel to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'The Reluctant Prince: An Unfinished Novel',
           'the-reluctant-prince-an-unfinished-novel',
           'An excerpt from a fantasy novel I''m writing for my daughter.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
