-- Deploy ovid:data/adventures-in-traveling to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Adventures in Traveling',
           'adventures-in-traveling',
           'Having lived in, and visited, multiple countries, I have loved my adventures.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
