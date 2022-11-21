-- Deploy ovid:data/my-21-weddings to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'My 21 Weddings',
           'my-21-weddings',
           'I have participated in 21 weddings. Twice as the groom, 17 times as the minister. It''s been a wild ride.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
