-- Deploy ovid:ddl/articles/dates to sqlite

BEGIN;

    -- Because SQLite is crap ...
    DROP TABLE articles;
    CREATE TABLE articles (
        article_id INTEGER PRIMARY KEY,
        title      VARCHAR(100) NOT NULL UNIQUE,
        slug       VARCHAR(100) NOT NULL UNIQUE,
        directory  VARCHAR(200) NOT NULL,
        sort_order INTEGER      NOT NULL UNIQUE,
        created    TEXT         NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('Case Study: 500 TPS'                            , 'project-500'                                    , '/articles' , '2019-09-18 05:36:05' , 20);
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('Moving from Oracle to PostgreSQL'               , 'moving-from-oracle-to-postgresql'               , '/articles' , '2019-07-20 09:35:55' , 19 );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('Managing a Remote Team'                         , 'managing-a-remote-team'                         , '/articles' , '2019-07-17 10:01:24' , 18 );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('Project Management in Three Numbers'            , 'project-management-in-three-numbers'            , '/articles' , '2019-06-05 10:27:30' , 17 );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('Alan Kay and Missing Messages (a follow-up)'    , 'alan-kay-and-missing-messages-a-follow-up'      , '/articles' , '2019-05-22 09:54:46' , 16 );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('Alan Kay and OO Programming'                    , 'alan-kay-and-oo-programming'                    , '/articles' , '2019-05-17 13:29:22' , 15 );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('The Worst Job Offer'                            , 'the-worst-job-offer'                            , '/articles' , '2019-05-17 09:40:47' , 14 );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('Software Projects as Used Cars'                 , 'the-tyranny-of-budgets'                         , '/articles' , '2019-05-14 16:48:39' , 13 );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('How to Defeat Facebook'                         , 'how-to-defeat-facebook'                         , '/articles' , '2019-04-28 10:37:13' , 12 );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('Fixing MVC in Web Applications'                 , 'fixing-mvc-in-web-applications'                 , '/articles' , '2019-04-17 11:41:02' , 11 );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('Avoid Common Software Project Mistakes'         , 'avoid-common-software-project-mistakes'         , '/articles' , '2019-04-11 13:11:11' , 10 );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('Estimating Development Costs is Almost Useless' , 'estimating-development-costs-is-almost-useless' , '/articles' , '2019-02-01 09:04:23' , 9 );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('The Surprises of A/B Testing'                   , 'the-surprises-of-ab-testing'                    , '/articles' , '2019-01-22 15:17:36' , 8 );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('GDPR and Bankruptcy'                            , 'gdpr-and-bankruptcy'                            , '/articles' , '2018-11-23 12:24:51' , 7 );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('Death by Database'                              , 'death-by-database'                              , '/articles' , '2018-09-19 18:34:09' , 6 );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('The Zen of test suites'                         , 'zen-of-test-suites'                             , '/articles' , '2018-09-16 23:46:07' , 5 );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('How the database can hurt your startup'         , 'how-databases-can-hurt-your-startup'            , '/articles' , '2018-09-16 23:16:25' , 4 );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('A simple way to fix legacy code'                , 'a-simple-way-to-fix-legacy-code'                , '/articles' , '2018-09-16 22:47:29' , 3 );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('When to choose agile'                           , 'when-to-choose-agile'                           , '/articles' , '2018-09-16 20:57:22' , 2 );
    INSERT INTO articles (title , slug , directory , created , sort_order) VALUES ('When going agile can hurt your company'         , 'going-agile-can-hurt-your-company'              , '/articles' , '2018-09-16 20:57:22' , 1 );

COMMIT;
