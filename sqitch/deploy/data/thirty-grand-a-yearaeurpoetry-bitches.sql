-- Deploy ovid:data/thirty-grand-a-yearaeurpoetry-bitches to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Thirty Grand A Year&mdash;Poetry, Bitches!',
           'thirty-grand-a-year-poetry-bitches',
           'Thirty Bob a Week is one of the greatest poems ever written. Time to update it for the modern era.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
