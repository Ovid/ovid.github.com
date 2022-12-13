-- Deploy ovid:data/is-spacex-stumbling to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Is SpaceX Stumbling?',
           'is-spacex-stumbling',
           'SpaceX is now the most valuable private company in the US, but it may be stumbling',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
