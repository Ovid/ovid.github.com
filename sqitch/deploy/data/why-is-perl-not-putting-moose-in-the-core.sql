-- Deploy ovid:data/why-is-perl-not-putting-moose-in-the-core to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Why is Perl not putting Moose in the core?',
           'why-is-perl-not-putting-moose-in-the-core',
           'People keep asking why the Perl language doesn''t just drag the Moose module into the core for object-oriented programming. Buckle up, this will be a long trip ...',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
