-- Deploy ovid:data/being-a-keynote-speaker to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Being a Keynote Speaker',
           'being-a-keynote-speaker',
           'I''ve been asked to give the opening keynote at the 25th anniversary of The Perl Conference/YAPC. It should be Larry, but he''s not able to attend.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
