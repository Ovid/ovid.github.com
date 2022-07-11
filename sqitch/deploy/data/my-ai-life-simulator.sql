-- Deploy ovid:data/my-ai-life-simulator to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'My AI Life Simulator',
           'my-ai-life-simulator',
           'Years ago I wrote a small AI life simulator. Debugging was ... fun.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
