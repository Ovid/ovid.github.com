-- Deploy ovid:data/automated-software-standards to sqlite

BEGIN;

    INSERT INTO articles (title, slug, article_type_id, sort_order)
         VALUES (
           'Automated Software Standards',
           'automated-software-standards',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
