-- Deploy ovid:data/resigning-from-the-perl-foundation to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Resigning From The Perl Foundation',
           'resigning-from-the-perl-foundation',
           'I''ve put this off for too long, but I''m resigning from The Perl Foundation.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
