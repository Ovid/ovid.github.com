-- Deploy ovid:data/learn-how-to-write-production-quality-code-with-ai to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Learn How to Write Production-Quality Code with AI',
           'learn-how-to-write-production-quality-code-with-ai',
           'Most systems to write code with AI use "AI-driven engineering." That lets the AI make too many decisions and this has led to the proliferation of "AI slop." This article introduces a free online-training I am offering to teach "engineering-led AI" using PAAD (https://github.com/Ovid/paad). You can still take advantage of AI, but now you have control of quality instead of the AI.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
