-- Deploy ovid:data/the-murder-of-george-floyd-and-the-new-civil-rights-movement to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'The Murder of George Floyd and The New Civil Rights Movement',
           'the-murder-of-george-floyd-and-the-new-civil-rights-movement',
           'The horrific video of the death of George Floyd at the hands of the police might just kick off a new civil rights movement.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
