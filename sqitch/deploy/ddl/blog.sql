-- Deploy ovid:ddl/blog to sqlite

BEGIN;

    CREATE TABLE article_types (
        article_type_id INTEGER PRIMARY KEY,
        name            VARCHAR(200) NOT NULL UNIQUE,
        type            VARCHAR(200) NOT NULL UNIQUE,
        directory       VARCHAR(200) NOT NULL UNIQUE
    );

    INSERT INTO article_types( name, type, directory )
      VALUES( 'Articles', 'article', 'articles' );
    INSERT INTO article_types( name, type, directory )
      VALUES( 'Blog Entries', 'blog', 'blog' );

    -- SQLite doesn't like you to alter existing columns. You can drop and
    -- recreate the table, or create a temp table, pull the data into it,
    -- drop the original, etc. Right now, drop/create is easier. As we have
    -- more data, the temp table solution will be better
    DROP TABLE articles;
    CREATE TABLE articles (
        article_id      INTEGER PRIMARY KEY,
        title           VARCHAR(100) NOT NULL,
        slug            VARCHAR(100) NOT NULL,
        article_type_id INTEGER      NOT NULL,
        sort_order      INTEGER      NOT NULL,
        created         TEXT         NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (article_type_id, sort_order),
        UNIQUE (article_type_id, title),
        UNIQUE (article_type_id, slug)
    );

    -- tech articles
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('Case Study: 500 TPS'                            , 'project-500'                                    , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2019-09-18 05:36:05' , 20);
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('Moving from Oracle to PostgreSQL'               , 'moving-from-oracle-to-postgresql'               , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2019-07-20 09:35:55' , 19 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('Managing a Remote Team'                         , 'managing-a-remote-team'                         , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2019-07-17 10:01:24' , 18 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('Project Management in Three Numbers'            , 'project-management-in-three-numbers'            , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2019-06-05 10:27:30' , 17 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('Alan Kay and Missing Messages (a follow-up)'    , 'alan-kay-and-missing-messages-a-follow-up'      , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2019-05-22 09:54:46' , 16 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('Alan Kay and OO Programming'                    , 'alan-kay-and-oo-programming'                    , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2019-05-17 13:29:22' , 15 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('The Worst Job Offer'                            , 'the-worst-job-offer'                            , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2019-05-17 09:40:47' , 14 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('Software Projects as Used Cars'                 , 'the-tyranny-of-budgets'                         , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2019-05-14 16:48:39' , 13 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('How to Defeat Facebook'                         , 'how-to-defeat-facebook'                         , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2019-04-28 10:37:13' , 12 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('Fixing MVC in Web Applications'                 , 'fixing-mvc-in-web-applications'                 , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2019-04-17 11:41:02' , 11 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('Avoid Common Software Project Mistakes'         , 'avoid-common-software-project-mistakes'         , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2019-04-11 13:11:11' , 10 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('Estimating Development Costs is Almost Useless' , 'estimating-development-costs-is-almost-useless' , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2019-02-01 09:04:23' , 9 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('The Surprises of A/B Testing'                   , 'the-surprises-of-ab-testing'                    , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2019-01-22 15:17:36' , 8 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('GDPR and Bankruptcy'                            , 'gdpr-and-bankruptcy'                            , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2018-11-23 12:24:51' , 7 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('Death by Database'                              , 'death-by-database'                              , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2018-09-19 18:34:09' , 6 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('The Zen of test suites'                         , 'zen-of-test-suites'                             , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2018-09-16 23:46:07' , 5 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('How the database can hurt your startup'         , 'how-databases-can-hurt-your-startup'            , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2018-09-16 23:16:25' , 4 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('A simple way to fix legacy code'                , 'a-simple-way-to-fix-legacy-code'                , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2018-09-16 22:47:29' , 3 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('When to choose agile'                           , 'when-to-choose-agile'                           , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2018-09-16 20:57:22' , 2 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('When going agile can hurt your company'         , 'going-agile-can-hurt-your-company'              , ( SELECT article_type_id FROM article_types WHERE type = 'article' ) , '2018-09-16 20:57:22' , 1 );

    -- blogs
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('A Eulogy for My Father'              , 'my-father'                          , ( SELECT article_type_id FROM article_types WHERE type = 'blog' ) , '2019-08-01 20:57:22' , 1 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('Missing Siblings?'                   , 'missing-siblings'                   , ( SELECT article_type_id FROM article_types WHERE type = 'blog' ) , '2019-11-01 20:57:22' , 2 );
    INSERT INTO articles (title , slug , article_type_id , created , sort_order) VALUES ('Why is zero factorial equal to one?' , 'why-is-zero-factorial-equal-to-one' , ( SELECT article_type_id FROM article_types WHERE type = 'blog' ) , '2019-12-01 20:57:22' , 3 );

COMMIT;
