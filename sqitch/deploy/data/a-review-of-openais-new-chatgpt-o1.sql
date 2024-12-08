-- Deploy ovid:data/a-review-of-openais-new-chatgpt-o1 to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'A Review of OpenAI''s new ChatGPT o1',
           'a-review-of-openais-new-chatgpt-o1',
           'OpenAI has released the new ChatGPT o1, removing the previous o1-preview model. Is it any good?',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
