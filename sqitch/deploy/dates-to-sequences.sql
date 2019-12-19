-- Deploy ovid:dates-to-sequences to sqlite

BEGIN;

	DROP TABLE articles;
	CREATE TABLE articles (
		article_id INTEGER PRIMARY KEY,
		title      VARCHAR(100) NOT NULL UNIQUE,
		slug       VARCHAR(100) NOT NULL UNIQUE,
		directory  VARCHAR(200) NOT NULL,
		sort_order INTEGER      NOT NULL UNIQUE
	);
    INSERT INTO articles (title , slug , directory , sort_order) VALUES ('Case Study: 500 TPS'                            , 'project-500'                                    , '/articles' , 20);
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('Moving from Oracle to PostgreSQL'               , 'moving-from-oracle-to-postgresql'               , '/articles' , 19 );
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('Managing a Remote Team'                         , 'managing-a-remote-team'                         , '/articles' , 18 );
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('Project Management in Three Numbers'            , 'project-management-in-three-numbers'            , '/articles' , 17 );
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('Alan Kay and Missing Messages (a follow-up)'    , 'alan-kay-and-missing-messages-a-follow-up'      , '/articles' , 16 );
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('Alan Kay and OO Programming'                    , 'alan-kay-and-oo-programming'                    , '/articles' , 15 );
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('The Worst Job Offer'                            , 'the-worst-job-offer'                            , '/articles' , 14 );
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('Software Projects as Used Cars'                 , 'the-tyranny-of-budgets'                         , '/articles' , 13 );
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('How to Defeat Facebook'                         , 'how-to-defeat-facebook'                         , '/articles' , 12 );
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('Fixing MVC in Web Applications'                 , 'fixing-mvc-in-web-applications'                 , '/articles' , 11 );
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('Avoid Common Software Project Mistakes'         , 'avoid-common-software-project-mistakes'         , '/articles' , 10 );
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('Estimating Development Costs is Almost Useless' , 'estimating-development-costs-is-almost-useless' , '/articles' , 9 );
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('The Surprises of A/B Testing'                   , 'the-surprises-of-ab-testing'                    , '/articles' , 8 );
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('GDPR and Bankruptcy'                            , 'gdpr-and-bankruptcy'                            , '/articles' , 7 );
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('Death by Database'                              , 'death-by-database'                              , '/articles' , 6 );
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('The Zen of test suites'                         , 'zen-of-test-suites'                             , '/articles' , 5 );
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('How the database can hurt your startup'         , 'how-databases-can-hurt-your-startup'            , '/articles' , 4 );
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('A simple way to fix legacy code'                , 'a-simple-way-to-fix-legacy-code'                , '/articles' , 3 );
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('When to choose agile'                           , 'when-to-choose-agile'                           , '/articles' , 2 );
	INSERT INTO articles (title , slug , directory , sort_order) VALUES ('When going agile can hurt your company'         , 'going-agile-can-hurt-your-company'              , '/articles' , 1 );

COMMIT;
