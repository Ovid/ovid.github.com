-- Deploy ovid:data/what-is-socialism to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'What Is Socialism?',
           'what-is-socialism',
           'Many people have strong opinions about socialism, which is curious since it''s hard to define it. So let''s try.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
