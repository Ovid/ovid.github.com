-- Deploy ovid:data/ai-for-accessibility to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'AI for Accessibility',
           'ai-for-accessibility',
           'Many people don''t write alt tags for images, or they write bad ones. However, these are crucial for people using screenreaders to understand the image. AI can make this easier.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
