-- Deploy ovid:data/how-i-landed-the-worst-best-job to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'How I Landed the Worst Best Job',
           'how-i-landed-the-worst-best-job',
           'I am often asked how I got into technology. This is that strange, strange story.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
