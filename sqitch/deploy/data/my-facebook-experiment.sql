-- Deploy ovid:data/my-facebook-experiment to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'My Facebook Experiment',
           'my-facebook-experiment',
           'I made a long, disciplined effort on Facebook to reach out and openly communicate with those whose views I do not share. This is what I discovered.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
