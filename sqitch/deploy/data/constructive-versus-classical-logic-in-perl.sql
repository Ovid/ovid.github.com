-- Deploy ovid:data/constructive-versus-classical-logic-in-perl to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Constructive Versus Classical Logic in Perl',
           'constructive-versus-classical-logic-in-perl',
           'Perl developers tend to think in terms of classical logic, but Perl fits constructive logic better.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
