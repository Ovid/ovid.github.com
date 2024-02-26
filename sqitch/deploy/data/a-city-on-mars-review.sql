-- Deploy ovid:data/a-city-on-mars-review to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           '"A City on Mars" Review',
           'a-city-on-mars-review',
           'Should we settle Mars? Is this ''rush to space'' a good thing? Kelly and Zach Weinersmith wrote a book about it.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
