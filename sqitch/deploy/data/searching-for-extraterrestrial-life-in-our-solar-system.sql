-- Deploy ovid:data/searching-for-extraterrestrial-life-in-our-solar-system to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Searching for Extraterrestrial Life in Our Solar System',
           'searching-for-extraterrestrial-life-in-our-solar-system',
           'We might find extraterrestrial life in our solar system. What does that mean and what might we find?',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
