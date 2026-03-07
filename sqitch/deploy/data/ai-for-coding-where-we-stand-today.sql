-- Deploy ovid:data/ai-for-coding-where-we-stand-today to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'AI for Coding: Where We Stand Today',
           'ai-for-coding-where-we-stand-today',
           'In the 1940s, changing a computer''s program meant rewiring it. Today, we can literally just tell it what to do, but how well does it work?',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
