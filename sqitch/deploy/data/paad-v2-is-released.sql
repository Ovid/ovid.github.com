-- Deploy ovid:data/paad-v2-is-released to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'PAAD v2 is Released!',
           'paad-v2-is-released',
           'PAAD v2.0.0 is now out. Weeks of personal use, plus feedback from others, has led to a version of PAAD that you can easily customize. Security is also improved.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
