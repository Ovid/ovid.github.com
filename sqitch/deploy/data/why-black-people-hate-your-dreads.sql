-- Deploy ovid:data/why-black-people-hate-your-dreads to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Why Black People Hate Your Dreads',
           'why-black-people-hate-your-dreads',
           'Many stereotypically "black" hairstyles are worn by white people. White people get upset when black people call this cultural appropriation, pointing out that these hairstyles existed long before today''s black people wore them. Who''s right? The answer is complicated.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
