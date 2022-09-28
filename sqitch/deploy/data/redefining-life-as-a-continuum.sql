-- Deploy ovid:data/redefining-life-as-a-continuum to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Redefining Life as a Continuum',
           'redefining-life-as-a-continuum',
           'I recently wrote about life being a continuum, not an either/or. Isaac Arthur made me realize it''s deeper than that.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
