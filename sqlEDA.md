# EDA using SQL (mySQL)

#### 6.1 million projects that contain Python
`SELECT COUNT(*) FROM project_languages WHERE language='Python';`
+----------+
| COUNT(*) |
+----------+
|  6109358 |
+----------+

#### 360k projects that use Python, have not been deleted, and were active in the past year (but really only last few months of 2016 since GitHub doesn't refresh often to update these dates)
```
SELECT COUNT(*) FROM (
    SELECT project_id FROM project_languages
    WHERE language='Python') t
LEFT JOIN projects ON t.project_id = projects.id
    WHERE projects.updated_at > DATE_SUB(now(), INTERVAL 1 YEAR)
    AND projects.deleted <> 1;
```
+----------+
| COUNT(*) |
+----------+
|   363567 |
+----------+

#### So, I'll use projects created in the past 6 MONTHS since the most recent project update is appearing as `2016-12-15` anyway
```
SELECT COUNT(*) FROM (
    SELECT project_id
    FROM project_languages
    WHERE language='Python') t
LEFT JOIN projects ON t.project_id = projects.id
    WHERE projects.created_at > DATE_SUB(now(), INTERVAL 6 MONTH)
    AND projects.deleted <> 1;
```
+----------+
| COUNT(*) |
+----------+
|   729466 |
+----------+
