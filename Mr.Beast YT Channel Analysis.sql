create database youtube_data;
USE youtube_data;
SHOW TABLES;
SELECT * FROM channel_info LIMIT 5;
SELECT * FROM videos LIMIT 5;
describe channel_info;
describe videos;
SELECT * FROM videoS WHERE title IS NULL OR views IS NULL; #checking for null values

#metrics analysis
#views to like ratio
ALTER TABLE videos ADD COLUMN view_like_ratio FLOAT;
UPDATE videos
SET view_like_ratio = CASE
    WHEN likes > 0 THEN views / likes
    ELSE NULL
END;

#engagement rate(likes and comments/views)
ALTER TABLE videos ADD COLUMN engagement_rate FLOAT; 
UPDATE videos
SET engagement_rate = CASE
    WHEN views > 0 THEN (likes + comments) / views
    ELSE 0
END;

#likes per comment ratio
ALTER TABLE videos ADD COLUMN like_comment_ratio FLOAT;
UPDATE videos
SET like_comment_ratio = CASE
    WHEN comments > 0 THEN likes / comments
    ELSE NULL
END;

#days since upload 
UPDATE videos
SET days_since_upload = DATEDIFF(CURDATE(), published_datetime);

#converting the date time format
ALTER TABLE videos ADD COLUMN published_datetime DATETIME;
UPDATE videos
SET published_datetime = STR_TO_DATE(
    REPLACE(REPLACE(publishedat, 'T', ' '), 'Z', ''),
    '%Y-%m-%d %H:%i:%s'
);
#creating new column based on the newly created date-time column
UPDATE videos
SET days_since_upload = DATEDIFF(CURDATE(), published_datetime);

#views per day
ALTER TABLE videos ADD COLUMN views_per_day FLOAT;
UPDATE videos
SET views_per_day = CASE
    WHEN days_since_upload > 0 THEN views / days_since_upload
    ELSE views
END;

#likes per day
ALTER TABLE videos ADD COLUMN likes_per_day FLOAT;
UPDATE videos
SET likes_per_day = CASE
    WHEN days_since_upload > 0 THEN likes / days_since_upload
    ELSE likes
END;

#is viral or not
ALTER TABLE videos ADD COLUMN is_viral BOOLEAN;
UPDATE videos
SET is_viral = CASE
    WHEN views > 10000000 AND engagement_rate > 0.05 THEN TRUE
    ELSE FALSE
END;

#hour of upload stat
ALTER TABLE videos ADD COLUMN upload_hour INT;
UPDATE videos
SET upload_hour = HOUR(published_datetime);

#day of week
ALTER TABLE videos ADD COLUMN upload_dayofweek INT;
UPDATE videos
SET upload_dayofweek = DAYOFWEEK(published_datetime) - 1;

#time since upload in hours
ALTER TABLE videos ADD COLUMN hours_since_upload INT;
UPDATE videos
SET hours_since_upload = TIMESTAMPDIFF(HOUR, published_datetime, NOW());

#weekend or weekday upload 
ALTER TABLE videos ADD COLUMN is_weekend TINYINT;
UPDATE videos
SET is_weekend = CASE
    WHEN DAYOFWEEK(published_datetime) IN (1, 7) THEN 1
    ELSE 0
END;

#creating a summary table
CREATE TABLE video_summary AS
SELECT
    video_id,
    title,
    published_datetime,
    views,
    likes,
    comments,
    
    -- Derived metrics
    DATEDIFF(CURDATE(), published_datetime) AS days_since_upload,
    TIMESTAMPDIFF(HOUR, published_datetime, NOW()) AS hours_since_upload,
    HOUR(published_datetime) AS upload_hour,
    DAYOFWEEK(published_datetime) - 1 AS upload_dayofweek,
    CASE
        WHEN DAYOFWEEK(published_datetime) IN (1, 7) THEN 1
        ELSE 0
    END AS is_weekend

FROM
    videos;

SELECT * FROM video_summary LIMIT 10;

SELECT @@secure_file_priv;

#to export it as csv
SELECT * 
FROM video_summary
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/video_summary.csv'
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n';




SELECT *  FROM video_summary INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/video_summary.csv' FIELDS TERMINATED BY ','  ENCLOSED BY '"'  LINES TERMINATED BY '\n'
