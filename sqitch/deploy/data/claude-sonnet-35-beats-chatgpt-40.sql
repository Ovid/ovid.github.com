-- Deploy ovid:data/claude-sonnet-35-beats-chatgpt-40 to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Claude Sonnet 3.5 beats ChatGPT 4.0',
           'claude-sonnet-35-beats-chatgpt-40',
           'I played with the new Claude Sonnet 3.5 AI and build a Javascript game.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
