-- Deploy ovid:data/ai-coding-typing-was-never-the-bottleneck to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'AI Coding: Typing Was Never the Bottleneck',
           'ai-coding-typing-was-never-the-bottleneck',
           'Code production was never the bottleneck in software development. Ths is why making it cheap doesn''t do what the replacement narrative claims it does.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
