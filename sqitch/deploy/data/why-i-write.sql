-- Deploy ovid:data/why-i-write to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Why I Write',
           'why-i-write',
           'I write. A lot. My muse sometimes shows up when I do. This is why I write.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
