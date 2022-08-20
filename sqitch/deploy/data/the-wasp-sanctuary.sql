-- Deploy ovid:data/the-wasp-sanctuary to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'The Wasp Sanctuary',
           'the-wasp-sanctuary',
           'Our house, to my surprise, is now a wasp sanctuary.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
