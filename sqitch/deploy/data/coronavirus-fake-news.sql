-- Deploy ovid:data/coronavirus-fake-news to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Coronavirus Fake News',
           'coronavirus-fake-news',
           'There is a lot of nonsense being peddled about the coronavirus. One article by a PhD in psychology is getting shared and it''s dangerous.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
