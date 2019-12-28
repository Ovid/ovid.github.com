-- Deploy ovid:data/will-it-rain-tomorrow to sqlite

BEGIN;

    INSERT INTO articles (title, slug, article_type_id, sort_order)
         VALUES (
           'Will It Rain Tomorrow?',
           'will-it-rain-tomorrow',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
