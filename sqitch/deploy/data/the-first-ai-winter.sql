-- Deploy ovid:data/the-first-ai-winter to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'The First AI Winter',
           'the-first-ai-winter',
           'Perplexity.ai has unveiled their own version of Deep Research. Let''s investigate the first AI Winter.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
