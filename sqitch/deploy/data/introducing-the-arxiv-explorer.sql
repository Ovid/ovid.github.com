-- Deploy ovid:data/introducing-the-arxiv-explorer to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Introducing the arXiv Explorer',
           'introducing-the-arxiv-explorer',
           'The arXiv Explorer uses a novel recursive language model technique to allow you to  use a normal AI-chat to query megabytes of arXiv documents at a time.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
