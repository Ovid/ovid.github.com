-- Deploy ovid:data/your-software-needs-feature-switches to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Feature Switch Best Practices',
           'feature-switch-best-practices',
           'One of the best things to come out of the DevOps movement is the promotion of feature switches. Let''s discuss best practices.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
