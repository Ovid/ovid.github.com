-- Deploy ovid:data/why-you-will-stay-no-to-living-abroad to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Why You Will Stay "No" to Living Abroad',
           'why-you-will-stay-no-to-living-abroad',
           'Many people fantasize about living abroad. However, if they''re given the chance, they might say no. Here''s why.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
