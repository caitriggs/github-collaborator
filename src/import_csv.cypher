// If doing this in neo4j browser, csv's must be in path: /Users/mac/Documents/Neo4j/default.graphdb/import

CREATE CONSTRAINT ON (o:Repo) ASSERT o.repoID IS UNIQUE;
CREATE CONSTRAINT ON (p:User) ASSERT p.userID IS UNIQUE;

// Create repo nodes
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM
"file:///home/ubuntu/db/data/active_projects.csv" AS row
FIELDTERMINATOR '\t'
CREATE (:Repo {repoID: toInt(row.id),
               url: row.url,
               userID: toInt(row.owner_id),
               name: row.name,
               description: row.description,
               mainLanguage: row.language,
               repoCreated: row.created_at,
               forkedFrom: toInt(row.forked_from)
               });

// Create user nodes
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM "file:///home/ubuntu/db/data/active_users.csv" AS row
FIELDTERMINATOR '\t'
CREATE (:User {userID: toInt(row.id),
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

// Create relationship between follower to user (user-user)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "file:///home/ubuntu/db/data/followers.csv" AS row
MATCH (follower:User {userID: toInt(row.follower_id)})
MATCH (user:User {userID: toInt(row.user_id)})
MERGE (follower)-[:FOLLOWS]->(user);

// Create relationship between original repo and forks (repo-repo)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "file:///home/ubuntu/db/data/active_projects.csv" AS row
FIELDTERMINATOR '\t'
MATCH (fork:Repo {repoID: toInt(row.id)})
MATCH (original:Repo {repoID: toInt(row.forked_from)})
MERGE (fork)-[:FORKED_FROM]->(original);

// Create relationship between user and owned repos (user-repo)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "file:///home/ubuntu/db/data/active_projects.csv" AS row
FIELDTERMINATOR '\t'
MATCH (user:User {userID: toInt(row.owner_id)})
MATCH (repo:Repo {repoID: toInt(row.id)})
MERGE (user)-[:OWNS]->(repo);

// Create relationship between user and org user (user-user)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "file:///home/ubuntu/db/data/organization_members.csv" AS row
MATCH (user:User {userID: toInt(row.user_id)})
MATCH (org:User {userID: toInt(row.org_id)})
MERGE (user)-[:MEMBER_OF]->(org);

// Create relationship between user and repo stars (user-repo)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "file:///home/ubuntu/db/data/watchers.csv" AS row
MATCH (user:User {userID: toInt(row.user_id)})
MATCH (repo:Repo {repoID: toInt(row.repo_id)})
MERGE (user)-[:STARRED]->(repo);

// Create relationship between user and repo forks (user-repo)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "file:///home/ubuntu/db/data/watchers.csv" AS row
MATCH (user:User {userID: toInt(row.user_id)})
MATCH (repo:Repo {repoID: toInt(row.repo_id)})
MERGE (user)-[:FORKED]->(repo);


---------------- FINDING RELATIONSHIPS BETWEEN NODES ------------------
// Return a user and its immediate relationships
MATCH (a:User {login: 'candlepin'})-[r]-(b)
RETURN r, a, b;
