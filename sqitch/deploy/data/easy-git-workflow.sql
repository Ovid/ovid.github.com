-- Deploy ovid:data/easy-git-workflow to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Easy Git Workflow',
           'easy-git-workflow',
           'This is the dead-easy git workflow used by All Around the World. Github repo included.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
