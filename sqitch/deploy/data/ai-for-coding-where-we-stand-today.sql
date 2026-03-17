-- Deploy ovid:data/ai-for-coding-where-we-stand-today to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Why I Am No Longer Reading the AI’s code',
           'why-i-am-no-longer-reading-the-ais-code',
           'I set out on a year-long quest to find out if we can really use AI to write production-quality code. I assumed the answer was no. I was wrong.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
