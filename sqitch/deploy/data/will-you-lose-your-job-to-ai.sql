-- Deploy ovid:data/will-you-lose-your-job-to-ai to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Will You Lose Your Job to AI?',
           'will-you-lose-your-job-to-ai',
           'Given the current worries about AI, people are worried about losing their jobs to it. You probably won''t. Yet.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
