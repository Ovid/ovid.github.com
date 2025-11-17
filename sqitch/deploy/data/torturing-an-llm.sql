-- Deploy ovid:data/torturing-an-llm to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Torturing an LLM',
           'torturing-an-llm',
           'I accidentally went down the rabbit hole of torturing Google Gemini 2.5 while looking for a seahorse.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
