-- Deploy ovid:data/an-agentic-harness-for-pocs to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'An agentic harness for POCs',
           'an-agentic-harness-for-pocs',
           'I have been thinking about building an open source agentic harness, similar to Devin or Lovable. Maybe call it Devable. It all started from a misunderstanding.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
