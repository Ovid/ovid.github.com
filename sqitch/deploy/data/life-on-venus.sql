-- Deploy ovid:data/life-on-venus to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Life on Venus?',
           'life-on-venus',
           'Scientists are excited about the discovery of phosphine on Venus. We don’t know of any natural prorcess which could cause this on Venus, but phosphine is regularly produced by life on Earth.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
