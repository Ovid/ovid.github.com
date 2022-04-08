-- Deploy ovid:data/flash-fiction-charlatans to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Flash Fiction: Charlatans',
           'flash-fiction-charlatans',
           'A flash fiction story I wrote as part of a writing prompt.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
