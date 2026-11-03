-- Deploy ovid:data/should-we-review-ai-generated-code to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Should We Review AI-generated Code?',
           'should-we-review-ai-generated-code',
           'Obviously, we should review AI-generted code. The real question is whether or not we can.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
