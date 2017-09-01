// If doing this in neo4j browser, csv's must be in path: /Users/mac/Documents/Neo4j/default.graphdb/import

// Create repo nodes
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM
"file:///active_projects.csv" AS row
CREATE (:Repo {repoID: row.id,
               url: row.url,
               userID: row.owner_id,
               name: row.name,
               mainLanguage: row.language,
               repoCreated: row.created_at,
               forkedFrom: row.forked_from
               });

// Create users
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM "file:///active_users1.csv" AS row
CREATE (:User {userID: row.id,
               login: row.login,
               company: row.company,
               userCreated: row.created_at,
               type: row.type,
               countryCode: row.country_code,
               state: row.state,
               city: row.city
               });

CREATE INDEX ON :Repo(repoID);
CREATE INDEX ON :User(userID);
CREATE INDEX ON :User(login);
CREATE INDEX ON :Repo(forkedFrom);

CREATE CONSTRAINT ON (o:Repo) ASSERT o.repoID IS UNIQUE;
CREATE CONSTRAINT ON (o:User) ASSERT o.userID IS UNIQUE;

// Create relationship between follower to user (user-user)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "file:///followers.csv" AS row
MATCH (follower:User {userID: row.follower_id})
MATCH (user:User {userID: row.user_id})
MERGE (follower)-[:FOLLOWS]->(user);

// Create relationship between original repo and forks (repo-repo)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "file:///active_projects.csv" AS row
MATCH (fork:Repo {repoID: row.id})
MATCH (original:Repo {repoID: row.forked_from})
MERGE (fork)-[:FORKED_FROM]->(original);

// Create relationship between user and owned repos (user-repo)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "file:///active_projects.csv" AS row
MATCH (user:User {userID: row.owner_id})
MATCH (repo:Repo {repoID: row.id})
MERGE (user)-[:OWNS]->(repo);

// Create relationship between user and org user (user-user)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "file:///org_members.csv" AS row
MATCH (user:User {userID: row.user_id})
MATCH (org:User {userID: row.org_id})
MERGE (user)-[:MEMBER_OF]->(org);


---------------- FINDING RELATIONSHIPS BETWEEN NODES ------------------
// Return a user and its immediate relationships
MATCH (a:User {login: 'candlepin'})-[r]-(b)
RETURN r, a, b;
