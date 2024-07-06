-- Deploy ovid:data/an-openai-chatbot-in-perl to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'An OpenAI Chatbot in Perl',
           'an-openai-chatbot-in-perl',
           'The OpenAPI::Client::OpenAI module is very low-level. We show how to write a wrapper around it for a clean interface with production code.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
