# Notes on project

### Starting MySQL on Ubuntu EC2 instance:
https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-16-04

### Setting up a db in mySQL:
https://www.digitalocean.com/community/tutorials/a-basic-mysql-tutorial

### Get zipped mySQL data dump:
http://ghtorrent.org/downloads.html

### Unzip mySQL dump:
`tar zxvf mysql-2017-07-01.tar.gz`

### Recreate mySQL db with csv files from GHTorrent dump:
https://github.com/gousiosg/github-mirror/tree/master/sql

### Created a new mySQL user and granted privileges using:
Start msql within ubuntu instance: `mysql -u root -p`  
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

### Config mySQL to allow loading files from anywhere:
`cd /etc/mysql`
`sudo vi my.cnf` (since anything in etc/ is read_only)
Add to the end of my.cnf:
    ```
    [mysqld]
    secure-file-priv = ""
    ```
### Config apparmor.d to include reading/writing to mysql in /db drive
`cd /etc/apparmor.d/`
Under the section '' add:
```

```

### Load csv files into new database using script provided:  
```
cd  mysql-2017-07-01
./ght-restore-mysql -u root -d ghtorrent_restore -p 0 .
```
---------
### Reading before starting
Pitfalls of data mining github http://etc.leif.me/papers/Kalliamvakou2015a.pdf
---------
## Game Plan
1. Get dataset loaded into mySQL db
2. Query dataset to subset to repos containing Python, active within 6 months, haven't been deleted; and where owner of repo has not been deleted, is not fake, and is not an organization
3. Create features that denote follows, stars, forks, and pull requests between users-repos
4. Create a graph that maps the similarity between clusters of users-repos who interact
5. Use graph to recommend other users or repos that the user within a cluster is similar to based on interactions
https://medium.com/@keithwhor/using-graph-theory-to-build-a-simple-recommendation-engine-in-javascript-ec43394b35a3

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
mysql ghtorrent_restore --password=0 < subset.sql | sed 's/\t/,/g' > followers100k.csv
```

## Copy file from remote instance to local
```
scp project:/home/ubuntu/db/followers10k.csv /Users/mac/Documents/DSI/github-collaborator/data/test_data
```
-------
## Playing with SQL queries

#### Some aggregative counts for number of rows in each table
`SELECT table_name, TABLE_ROWS
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'github';`

#### Select only projects containing Python
`SELECT project_id FROM project_languages
WHERE language = 'Python';`

#### Select only projects updated within last 6 months
`SELECT COUNT(*) FROM projects
WHERE updated_at > DATE_SUB(now(), INTERVAL 1 YEAR)
AND deleted <> 1
AND language = 'Python';`

#### Check if field is unique
`select sha, count(*) as count
from commits
group by sha
having count(*) > 1`

#### Randomly sample 100,000 rows of table
`SELECT * FROM followers
WHERE id IN (
  SELECT CAST(round(random() * 21e6) AS integer) AS id
  FROM generate_series(1, 100001) -- Doesnt work bc generate_series not in mysql
  GROUP BY id
)
LIMIT 100000;`

#### Slow way to randomly sample but it works!
`select * from followers
order by rand()
limit 10000;`
-----------
## Funky Town

- The most recently updated repo/project is `2016-12-16 10:00:49` in the newest 2017-07-01 data dump at GHTorrent. This is funky.
    - GHTorrent mentioned this is likely due to GitHub not updating all their info every time a change is made in a repo. "GitHub only 'refreshes' every X months"


--------
## Subsetting the data
1. Find repos using Python, active within past year or created in past month (see notes about this in 'Funky Town')
```
CREATE TABLE active_projects SELECT * FROM (
    SELECT t.project_id, projects.owner_id, t.language, projects.language as main_lang,
        t.python_bytes, projects.url, projects.name, projects.description,
        projects.forked_from, projects.deleted, projects.updated_at, projects.created_at
        FROM (
            SELECT project_id, language, bytes as python_bytes
            FROM project_languages
            WHERE language='Python') t
    LEFT JOIN projects ON t.project_id = projects.id
        WHERE projects.updated_at > DATE_SUB('2017-07-01', INTERVAL 1 YEAR)
        OR projects.created_at > DATE_SUB('2017-07-01', INTERVAL 1 MONTH)
        AND projects.deleted <> 1
    ) z;
```
2.
---------
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
