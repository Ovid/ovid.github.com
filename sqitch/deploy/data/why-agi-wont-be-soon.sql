-- Deploy ovid:data/why-agi-wont-be-soon to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Why AGI won''t be soon',
           'why-agi-wont-be-soon',
           'There''s been a lot of talk about AGI coming soon, but there are some strong reasons to think this isn''t true.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
