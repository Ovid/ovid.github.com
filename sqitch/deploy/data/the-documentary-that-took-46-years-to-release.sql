-- Deploy ovid:data/the-documentary-that-took-46-years-to-release to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'The Documentary That Took 46 Years to Release',
           'the-documentary-that-took-46-years-to-release',
           'The "Amazing Grace" documentary of Aretha Franklin creating the best-selling gospel R&B album of all time took 46 years to release. The story of how it happened is hilarious.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
