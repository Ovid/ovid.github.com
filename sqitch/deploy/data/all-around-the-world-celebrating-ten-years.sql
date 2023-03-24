-- Deploy ovid:data/all-around-the-world-celebrating-ten-years to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'All Around the World: Celebrating Ten Years',
           'all-around-the-world-celebrating-ten-years',
           'All Around the World started ten years ago as a Perl consultancy. We''ve grown quite a bit since then.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
