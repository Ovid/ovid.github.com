-- Deploy ovid:data/escape-adventurs-in-ai-gaming to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Escape!-Adventurs in AI Gaming',
           'escape-adventurs-in-ai-gaming',
           'I have updated my previous work with Claude to dramatically improve a Javascript game.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
