-- Deploy ovid:data/using-github-copilot-with-vim to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Using Github Copilot with Vim',
           'using-github-copilot-with-vim',
           'I''ve started using Github Copilot. Color me impressed.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
