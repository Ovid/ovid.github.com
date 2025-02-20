-- Deploy ovid:data/getting-a-job-offer-in-another-country to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Getting a Job Offer In Another Country',
           'getting-a-job-offer-in-another-country',
           'Many people don''t realize this, but getting a job in another country is not that hard ... if you''re a skilled worker. You just need to know how to stand out.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
