-- Deploy ovid:data/europe-must-support-ukraine to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Europe Must Support Ukraine',
           'europe-must-support-ukraine',
           'The US is turning its back on Ukraine. What now?',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
