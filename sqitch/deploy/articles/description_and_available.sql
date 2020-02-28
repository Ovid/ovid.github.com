-- Deploy ovid:articles/description_and_available to sqlite

BEGIN;

    --
    -- Creating our new table
    -- 
    CREATE TABLE articles_1582879379 (
            article_id      INTEGER PRIMARY KEY,
            title           VARCHAR(100)   NOT NULL,
            slug            VARCHAR(100)   NOT NULL,
            description     VARCHAR(1000) NOT NULL,
            article_type_id INTEGER        NOT NULL,
            sort_order      INTEGER        NOT NULL,
            available       BOOLEAN        NOT NULL DEFAULT TRUE,
            created         TEXT           NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE (article_type_id, sort_order),
            UNIQUE (article_type_id, title),
            UNIQUE (article_type_id, slug)
        );


    --
    -- Manually alter each of these insert statements as needed
    --

    INSERT INTO articles_1582879379 VALUES(1,'Case Study: 500 TPS','project-500','We had 14 days to increase a client''s performance from 39 transactions per second, to 500. This is how we did it.',1,20,TRUE,'2019-09-18 05:36:05');
    INSERT INTO articles_1582879379 VALUES(2,'Moving from Oracle to PostgreSQL','moving-from-oracle-to-postgresql','Moving from Oracle to PostgreSQL can save you a lot of money and pain. Here are the steps you need to take.',1,19,TRUE,'2019-07-20 09:35:55');
    INSERT INTO articles_1582879379 VALUES(3,'Managing a Remote Team','managing-a-remote-team','More and more companies are discovering that hiring remote workers gives them access to more workers an is better for the environment. This is a guide about how to manage your new remote teams.',1,18,TRUE,'2019-07-17 10:01:24');
    INSERT INTO articles_1582879379 VALUES(4,'Project Management in Three Numbers','project-management-in-three-numbers','New to project management or product ownership? Here are three simple numbers that will make your work much easier.',1,17,TRUE,'2019-06-05 10:27:30');
    INSERT INTO articles_1582879379 VALUES(5,'Alan Kay and Missing Messages (a follow-up)','alan-kay-and-missing-messages-a-follow-up','Many people struggled with my article about Alan Kay and OO programming, so let''s talk about the main objection.',1,16,TRUE,'2019-05-22 09:54:46');
    INSERT INTO articles_1582879379 VALUES(6,'Alan Kay and OO Programming','alan-kay-and-oo-programming','Dr. Alan Kay invented the term "OO Programming", but he states that modern OO programming isn''t what he meant. What did he mean?',1,15,TRUE,'2019-05-17 13:29:22');
    INSERT INTO articles_1582879379 VALUES(7,'The Worst Job Offer','the-worst-job-offer','A short rant about one of the worst job offers I''ve received, from a company I very much wanted to work for.',1,14,TRUE,'2019-05-17 09:40:47');
    INSERT INTO articles_1582879379 VALUES(8,'Software Projects as Used Cars','the-tyranny-of-budgets','Budgets are important, but their constraints can cost you more money than if you didn''t have them.',1,13,TRUE,'2019-05-14 16:48:39');
    INSERT INTO articles_1582879379 VALUES(9,'How to Defeat Facebook','how-to-defeat-facebook','A long, detailed explanation of what a "Facebook killer" would really look like.',1,12,TRUE,'2019-04-28 10:37:13');
    INSERT INTO articles_1582879379 VALUES(10,'Fixing MVC in Web Applications','fixing-mvc-in-web-applications','Almost every example of "MVC for the Web" makes the same mistakes, costing my clients money. Here''s how to fix them.',1,11,TRUE,'2019-04-17 11:41:02');
    INSERT INTO articles_1582879379 VALUES(11,'Avoid Common Software Project Mistakes','avoid-common-software-project-mistakes','When I get called in to fix a client''s software, I find that most large codebases have common errors. Here are some of them and how to avoid them.',1,10,TRUE,'2019-04-11 13:11:11');
    INSERT INTO articles_1582879379 VALUES(12,'Estimating Development Costs is Almost Useless','estimating-development-costs-is-almost-useless','Every manager wants an estimate of the cost of developing a new software project. That estimate is almost worthless. Here''s what you should really be measuring.',1,9,TRUE,'2019-02-01 09:04:23');
    INSERT INTO articles_1582879379 VALUES(13,'The Surprises of A/B Testing','the-surprises-of-ab-testing','A/B testing is about testing your customers, not your software.',1,8,TRUE,'2019-01-22 15:17:36');
    INSERT INTO articles_1582879379 VALUES(14,'GDPR and Bankruptcy','gdpr-and-bankruptcy','If you have EU customers and you''re uncertain how GDPR impacts you, stop reading this and hire a lawyer. Now.',1,7,TRUE,'2018-11-23 12:24:51');
    INSERT INTO articles_1582879379 VALUES(15,'Death by Database','death-by-database','A true story of a company that had a very, very simple feature request. Except that their database was such a mess that they had to abandon the idea.',1,6,TRUE,'2018-09-19 18:34:09');
    INSERT INTO articles_1582879379 VALUES(16,'The Zen of test suites','zen-of-test-suites','An overview of some basic test suite tips that are nonetheless overlooked.',1,5,TRUE,'2018-09-16 23:46:07');
    INSERT INTO articles_1582879379 VALUES(17,'How the database can hurt your startup','how-databases-can-hurt-your-startup','The sad truth is that most developers don''t know how to design a database and that''s an expensive mistake.',1,4,TRUE,'2018-09-16 23:16:25');
    INSERT INTO articles_1582879379 VALUES(18,'A simple way to fix legacy code','a-simple-way-to-fix-legacy-code','Fixing a legacy codebase is hard, but safer than rewriting. Here are some guidelines to make this easier.', 1,3,TRUE,'2018-09-16 22:47:29');
    INSERT INTO articles_1582879379 VALUES(19,'When to choose agile','when-to-choose-agile','Agile is wonderful, but there are times when you don''t want it.',1,2,TRUE,'2018-09-16 20:57:22');
    INSERT INTO articles_1582879379 VALUES(20,'When going agile can hurt your company','going-agile-can-hurt-your-company','Me ranting about agile again.',1,1,TRUE,'2018-09-16 20:57:22');
    INSERT INTO articles_1582879379 VALUES(21,'A Eulogy for My Father','my-father','My father passed away recently. His life was a whirlwind of travel from country to country under mysterious circumstances.',2,1,TRUE,'2019-08-01 20:57:22');
    INSERT INTO articles_1582879379 VALUES(22,'Missing Siblings?','missing-siblings','Apparently I may have one of two siblings raised in the former Soviet Union.',2,2,TRUE,'2019-11-01 20:57:22');
    INSERT INTO articles_1582879379 VALUES(23,'Why is zero factorial equal to one?','why-is-zero-factorial-equal-to-one','A quick explanation of why the factorial of zero is one, not zero.',2,3,TRUE,'2019-12-01 20:57:22');
    INSERT INTO articles_1582879379 VALUES(24,'Babylonian Numbers for 8-Year Olds','babylonian-numbers-for-8-year-olds','Wherein I explaine Babylonian numbers to my eight year old daughter and now explain them to you.',2,21,TRUE,'2019-12-28 11:14:10');
    INSERT INTO articles_1582879379 VALUES(25,'Will It Rain Tomorrow?','will-it-rain-tomorrow','If every hour has a 10% change of rain, what are the odds it will rain tomorrow?',2,22,TRUE,'2019-12-28 13:33:07');
    INSERT INTO articles_1582879379 VALUES(26,'Moose "has" a Problem','moose-has-a-problem','For Perl developers, I explain some of the problems with Moo''s "has" function.',2,23,TRUE,'2019-12-31 10:05:27');
    INSERT INTO articles_1582879379 VALUES(27,'Automated Software Standards','automated-software-standards','Spaces versus tabs? Cuddled elses? I don''t care what you believe. Just believe. And automate it.',1,24,TRUE,'2020-01-05 10:10:50');
    INSERT INTO articles_1582879379 VALUES(28,'Database Design Standards','database-design-standards','When I get called in to fix a client''s software, I find that most large codebases have common errors. Here are some of them and how to avoid them.',1,25,TRUE,'2020-01-07 16:46:48');


    DROP TABLE articles;
    ALTER TABLE articles_1582879379 RENAME TO articles;

COMMIT;
