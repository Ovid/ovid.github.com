-- Deploy ovid:data/ai-today-is-like-the-early-internet to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'AI Today Is Like the Early Internet',
           'ai-today-is-like-the-early-internet',
           'AI has entered an era similar to the internet near the end of 1996. Basic use cases were solid, advanced use cases were not, and money was flushed down the toilet.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
