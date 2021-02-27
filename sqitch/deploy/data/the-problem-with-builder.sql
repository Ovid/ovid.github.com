-- Deploy ovid:data/the-problem-with-builder to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Classes Should Not Override Parent Attributes',
           'the-problem-with-builder',
           'Slot/attribute builders in OO languages can be dangerous if you can inherit them.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
