-- Deploy ovid:data/ai-generated-content-innovation-or-intellectual-theft to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'AI-Generated Content: Innovation or Intellectual Theft?',
           'ai-generated-content-innovation-or-intellectual-theft',
           'Many people are upset that AI is ''learning'' from their work and producing derivative content. Should they be?',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
