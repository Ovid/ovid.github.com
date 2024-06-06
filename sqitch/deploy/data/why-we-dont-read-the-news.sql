-- Deploy ovid:data/why-we-dont-read-the-news to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Why We Don''t Read the News',
           'why-we-dont-read-the-news',
           'It''s sad that we don''t read the news any more, and it''s because of what advertising has done to the news structure.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
