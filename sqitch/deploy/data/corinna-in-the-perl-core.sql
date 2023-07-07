-- Deploy ovid:data/corinna-in-the-perl-core to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Corinna in the Perl Core',
           'corinna-in-the-perl-core',
           'Corinna is finally going into the Perl core. Here is a bit about the process.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
