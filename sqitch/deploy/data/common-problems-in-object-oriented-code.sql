-- Deploy ovid:data/common-problems-in-object-oriented-code to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Common Problems in Object-Oriented Code',
           'common-problems-in-object-oriented-code',
           'At https://allaroundtheworld.fr/, we are often fixing common issues in object-oriented code. This is a practical guide for resolving them.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
