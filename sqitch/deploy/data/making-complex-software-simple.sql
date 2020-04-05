-- Deploy ovid:data/making-complex-software-simple to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Making Complex Software Simple',
           'making-complex-software-simple',
           'In the Tau Station MMORPG, we have hideously complex software requirements that are very easy to manage. This article explains how you can do it to.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
