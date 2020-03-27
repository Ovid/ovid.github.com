-- Deploy ovid:data/work-from-home-effectively to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Work From Home Effectively',
           'work-from-home-effectively',
           'Many people are now working from home for the first time. It can be challenging, but here are some tips to make it easier.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
