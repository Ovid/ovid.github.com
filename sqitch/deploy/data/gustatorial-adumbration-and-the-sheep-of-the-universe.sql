-- Deploy ovid:data/gustatorial-adumbration-and-the-sheep-of-the-universe to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Gustatorial Adumbration and the Sheep of the Universe',
           'gustatorial-adumbration-and-the-sheep-of-the-universe',
           'Years ago I lived in London in a hotel with a few dozen of my closest colleagues. Some adventures ensued.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
