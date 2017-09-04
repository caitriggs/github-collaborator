# Notes on github-collaborator project
### Setup an EC2 instance and add the pem file to .ssh directory
ssh into the instance once HostName is set inside .ssh/config with `ssh project`

### See how much space on disks in the instance
`df -h`

### Create a disk with more space on instance.. aka remount EBS volume if it becomes unmounted
https://n2ws.com/how-to-guides/connect-aws-ebs-volume-another-instance.html
1. Go to AWS under EBS > Volumes > Actions button > Attach Volume (keep all defaults)
2. "Reboot" instance and ssh back into project instance
3. `sudo vi /etc/fstab` and add the following line to the bootom of the file:  
`/dev/xvdf   /home/ubuntu/db  ext4      defaults,nofail     0     2`
4. `sudo mount /dev/xvdf` to mount the EBS volume to /home/ubuntu/db
5. `df -h` to see the storage and where the storage is mounted to
6. `cd ~/db` to see files that were saved in the last snapshot save of that volume

### Starting MySQL on Ubuntu EC2 instance:
https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-16-04

### Setting up a db in mySQL:
https://www.digitalocean.com/community/tutorials/a-basic-mysql-tutorial

### Get zipped mySQL data dump:
http://ghtorrent.org/downloads.html
`wget https://ghtstorage.blob.core.windows.net/downloads/mysql-2017-07-01.tar.gz`

### Unzip mySQL dump:
`tar zxvf mysql-2017-07-01.tar.gz`

### Config mySQL to allow loading files from anywhere:
`sudo vi /etc/mysql/my.cnf`
Add to the end of my.cnf:
    ```
    [mysqld]
    secure-file-priv = ""
    ```
then restart mysql
`sudo service mysql restart`

### Config apparmor.d to include reading/writing to mysql in /db directories
`sudo vi /etc/apparmor.d/usr.sbin.mysqld`
Under the section '# Allow data dir access' add access to following directories:
```
  /home/ubuntu/db/mysql/ r,
  /home/ubuntu/db/mysql/** rwk,
  /home/ubuntu/db/mysql-2017-07-01/ r,
  /home/ubuntu/db/mysql-2017-07-01/** r,
  /home/ubuntu/db/data/ r,
  /home/ubuntu/db/data/** rwk,
```
then reload apparmor
`sudo service apparmor reload`
OR `sudo /etc/init.d/apparmor reload`

### Give mysql access to write to the data directory added above
`cd /home/ubuntu/db`
`sudo chown ubuntu:mysql data`

### Recreate mySQL db with csv files from GHTorrent dump:
https://github.com/gousiosg/github-mirror/tree/master/sql

### Created a new mySQL user and granted privileges using:
Start mysql within ubuntu instance: `mysql -u root -p` OR `mysql -u ubuntu -p` (not sure of the difference)
password: 0  
```
create user root@'localhost' identified by '0';
create user root@'*' identified by '0';
```
then
```
create database ghtorrent_restore;
grant all privileges on ghtorrent_restore.* to 'root'@'localhost';
grant all privileges on ghtorrent_restore.* to 'root'@'*';
grant file on *.* to 'root'@'localhost';
```

### Load csv files into new database using ght-restore-mysql script   
```
cd  mysql-2017-07-01
./ght-restore-mysql -u root -d ghtorrent_restore -p 0 .
```
---------
### Read after running into issues. (Hindsight is 20/20)
Pitfalls of data mining github http://etc.leif.me/papers/Kalliamvakou2015a.pdf
- Check the updated_at field
- created_at timestamp often occurs in 1970 and after present time. Clocks not configured correctly for those users. Use anyway as long as satisfied by other clauses?
- Data from every field not always as up to date as the date the dump was created since GitHub does not update associated metadata in real-time across the entire site

---------
## Game Plan
1. Get dataset loaded into mySQL db
2. Query dataset to subset to repos containing Python, active within X months, haven't been deleted; and where user has not been deleted, is not fake, and has a connection to the subset repos
3. Create relationships that denote follows, watches (stars), forks, and pull requests between users-repos nodes. Use Neo4j graph database to define these relationships
4. Use Neo4j graph to find the degree of cpnnection between users-repos who interact. aka find clusters of communities
5. Of those degree connected repos, find the cosine similarity between their README.md files adn return X-top similar repos


etc:
- https://neo4j.com/developer/guide-build-a-recommendation-engine/
- https://medium.com/@keithwhor/using-graph-theory-to-build-a-simple-recommendation-engine-in-javascript-ec43394b35a3

---------
# Workflows for working on ssh and local
## Reconnecting to tmux
```
$ tmux
$ make <something big>
......
Connection fails for some reason
Reconnect

$ tmux ls
0: 1 windows (created Tue Aug 23 12:39:52 2011) [103x30]

$ tmux attach -t 0
Back in the tmux sesion

$ tmux kill-window -t 0
Kill your old windows
```

## Pipe contents of SQL query to a csv file
```
mysql -u root -p github -e "select * from followers" -B | sed "s/'/\'/;s/\t/\",\"/g;s/^/\"/;s/$/\"/;s/\n//g" > followers.csv
```

## Copy file from remote instance to local
```
scp project:/home/ubuntu/db/followers10k.csv /Users/mac/Documents/DSI/github-collaborator/data/test_data
```

## Add content before first line of file with sed
`sed  -i '1i text goes here' filename`

## Remove first line of file with sed
`sed -i '1d' filename`

-------
## Playing with SQL queries

#### Some aggregative counts for number of rows in each table
```
SELECT table_name, TABLE_ROWS
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'github';
```

#### Select projects containing Python
```
SELECT DISTINCT(project_id) FROM project_languages
WHERE language = 'Python';
```

#### Check if field is unique
```
select sha, count(*) as count
from commits
group by sha
having count(*) > 1
```

#### Randomly sample 100,000 rows of table
```
SELECT * FROM followers
WHERE id IN (
  SELECT CAST(round(random() * 21e6) AS integer) AS id
  FROM generate_series(1, 100001) -- Doesnt work bc generate_series not in mysql
  GROUP BY id
)
LIMIT 100000;
```

#### Slow way to randomly sample but it works!
```
select * from followers
order by rand()
limit 10000;
```

#### Copy a table from one db to another
```
CREATE TABLE github.commits SELECT * FROM ghtorrent_restore.commits;
```
-----------
## Funky Town

- The most recently updated repo/project is `2016-12-16 10:00:49` in the newest 2017-07-01 data dump at GHTorrent. This is funky.
    - "GitHub only 'refreshes' every X months", but GHTorrent confirmed the `updated_at` field is used by GHTorrent to denote when they last did a full refresh of that entry, NOT when the repo was last updated by a user

--------
## Subsetting the data
1. Find repos using Python as main language, was not deleted, and had commits in the past 1 MONTH (see notes about this in 'Funky Town'). table: active_projects
```
CREATE TABLE active_projects
    SELECT * FROM projects
    WHERE projects.id IN
        (-- Project IDs which had commits in past MONTH
            SELECT DISTINCT(recent_commits.project_id)
            FROM recent_commits
            WHERE recent_commits.created_at > DATE_SUB('2017-07-01 00:00:00', INTERVAL 1 YEAR)
            AND recent_commits.created_at < '2017-07-01 00:00:00'
        )
    AND projects.language = 'Python'
    AND projects.deleted <> 1;
```
2. Find active users associated with the subset of projects. table: active_users
```
CREATE TABLE active_users
SELECT * FROM users
WHERE users.id IN (
    SELECT DISTINCT(active_projects_1MONTH.owner_id)
    FROM active_projects_1MONTH
)
AND users.fake <> 1
AND users.deleted <> 1;
```

---------
## Create graph database from the subset data using Neo4j

#### Nodes:
- User
- Repo

#### Relationships/Edges:
- FOLLOWS | user -> user
- FORKED_FROM | repo -> repo
- OWNS | user -> repo
- MEMBER_OF | user -> user
- WATCHES | user -> repo


1. Download neo4j and setup $PATH to run `cypher-shell` and `neo4j-shell`
    - Ended up just using the browser GUI since the shell wasn't working well
    - Startup the neo4j server and go to `http://127.0.0.1:7474/browser/`
2. CSVs must be in the defaultdb `/Users/mac/Documents/Neo4j/default.graphdb/import` for neo4j for import in the browser to work (couldn't figure out the elusive neo4j.conf file remedy)
```
// Create repo nodes
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM "file:///active_projects.csv" AS row
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
```

3. Create relationships between nodes
```
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
```

--------
## The Recommendation Pipeline
1. Use Neo4j graph to traverse graph from a User between 2nd and X degrees
2.


------------------------
#  RANDOM STUFF YONDER

## Clustering
#### TF-IDF Matrix from commit messages:
http://jonathanzong.com/blog/2013/02/02/k-means-clustering-with-tfidf-weights
-------------
## Recommender  
#### Surprise:
http://surpriselib.com/
------------
## Social graph
#### Networkx: creating graphs
https://networkx.github.io/  
specifically, converting a numpy matrix into a graph object
https://networkx.readthedocs.io/en/stable/reference/convert.html

#### Gephi: visualizing graphs
https://gephi.org/users/quick-start/

other sites:
https://blog.dominodatalab.com/social-network-analysis-with-networkx/
