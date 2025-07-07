-- Deploy ovid:data/rip-mst to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'RIP MST',
           'rip-mst',
           'Long-time Perl legend and gadfly Matt Trout has passed.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
