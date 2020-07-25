-- Deploy ovid:data/dont-defund-the-police to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Don''t Defund The Police',
           'dont-defund-the-police',
           'Defunding the police is a hot, misunderstood, controversial topic. But there may be a middle ground that is easier to implement and satisfies more people.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
