-- Deploy ovid:data/building-an-iphone-app-with-chatgpt to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Building an iPhone App with ChatGPT',
           'building-an-iphone-app-with-chatgpt',
           'I''m still regularly amazed at how many developers dismiss Copilot and ChatGPT as ''stochastic parrots.'' These parrots are much smarter than they think.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
