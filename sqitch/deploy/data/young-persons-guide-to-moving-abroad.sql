-- Deploy ovid:data/young-persons-guide-to-moving-abroad to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Young Person''s Guide to Moving Abroad',
           'young-persons-guide-to-moving-abroad',
           'If you''re a highly skilled professional, moving abroad is easier. Here''s a guide for those who don''t have those skills.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
