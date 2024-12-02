-- Deploy ovid:data/prompt-engineering-is-not-dead to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Prompt Engineering Is Not Dead',
           'prompt-engineering-is-not-dead',
           'Many prompt engineering tricks are becoming a thing of the past, but there are still some areas where they shine.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
