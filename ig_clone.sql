use ig_clone;
-- We want to reward the user who has been around the longest, Find the 5 oldest users. --2

SELECT * FROM users
ORDER BY created_at
LIMIT 5;

-- To understand when to run the ad campaign, figure out the day of the week most users register on? --3

SELECT 
    DAYNAME(created_at) AS day,
    COUNT(*) AS total
FROM users
GROUP BY day
ORDER BY total DESC
LIMIT 1;

-- To target inactive users in an email ad campaign, find the users who have never posted a photo. --4

SELECT users.id, username FROM users
LEFT JOIN photos ON users.id = photos.user_id
WHERE photos.user_id IS NULL;
select * from photos;

-- Suppose you are running a contest to find out who got the most likes on a photo. Find out who won? --5
SELECT users.username,photos.id,photos.image_url,COUNT(*) AS Total_Likes
FROM likes
JOIN photos ON photos.id = likes.photo_id
JOIN users ON users.id = likes.user_id
GROUP BY photos.id
ORDER BY Total_Likes DESC
LIMIT 1;

-- The investors want to know how many times does the average user post. --6
SELECT ROUND((SELECT COUNT(*)FROM photos)/(SELECT COUNT(*) FROM users),2) avg;

-- A brand wants to know which hashtag to use on a post, and find the top 5 most used hashtags. --7

SELECT tags.id, tags.tag_name, COUNT(*) AS total
FROM tags
INNER JOIN photo_tags
  ON tags.id = photo_tags.tag_id
GROUP BY tags.id
ORDER BY total DESC
LIMIT 5;

SELECT tag_name, COUNT(tag_name) AS total
FROM tags
JOIN photo_tags ON tags.id = photo_tags.tag_id
GROUP BY tags.id
ORDER BY total DESC;

-- To find out if there are bots, find users who have liked every single photo on the site. --8
 
SELECT users.id,username, COUNT(users.id) As total_likes_by_user #bots
FROM users
JOIN likes ON users.id = likes.user_id
GROUP BY users.id, username
HAVING total_likes_by_user = (SELECT COUNT(*) FROM photos);

-- To know who the celebrities are, find users who have never commented on a photo. --9

SELECT U.USERNAME, COUNT(C.USER_ID) AS COMMENTED_ON_PHOTOS FROM USERS U 
LEFT OUTER JOIN COMMENTS C ON C.USER_ID=U.ID
GROUP BY U.USERNAME
HAVING COMMENTED_ON_PHOTOS=0;


select * from users u
where not exists (select 'X' 
                   from comments c
                  where u.id = c.user_id
                );
  
 
-- Now it's time to find both of them together, find the users who have never commented on any photo or have commented on every photo. --10

-- 1st USING CASE STATEMENT. 

SELECT USERNAME, ID, (SELECT COUNT(PHOTO_ID) FROM COMMENTS WHERE COMMENTS.USER_ID=USERS.ID) NOC, 
CASE WHEN ID IN (SELECT ID FROM USERS WHERE ID NOT IN (SELECT USER_ID FROM COMMENTS)) 
THEN "NOT COMMENTED ON ANY PHOTOS #CELEBRETIES"
WHEN ID IN (SELECT ID FROM USERS U INNER JOIN
(SELECT USER_ID, COUNT(PHOTO_ID) CT FROM COMMENTS 
GROUP BY USER_ID ORDER BY CT DESC) S 
ON S.USER_ID=U.ID 
WHERE CT=(SELECT COUNT(ID) FROM PHOTOS)) THEN "COMMENTED ON EVERY PHOTO #BOT"
ELSE "COMMENETED ON FEW PHOTOS #COMMON USER"
END AS COMMENT FROM USERS 
ORDER BY NOC DESC;

-- 2nd using cte with case statement. 
WITH CTE1 (USERNAME,ID,COMMENTED_ON_PHOTOS) AS
(SELECT U.USERNAME, U.ID, COUNT(C.USER_ID) AS COMMENTED_ON_PHOTOS FROM USERS U 
LEFT OUTER JOIN COMMENTS C ON C.USER_ID=U.ID
GROUP BY U.USERNAME
HAVING COMMENTED_ON_PHOTOS=0), 
CTE2 (USERNAME,ID,COMMENTED_ON_PHOTOS) AS
(SELECT U.USERNAME, U.ID, COUNT(C.USER_ID) AS COMMENTED_ON_PHOTOS FROM USERS U 
INNER JOIN COMMENTS C ON U.ID = C.USER_ID
GROUP BY U.USERNAME 
HAVING COMMENTED_ON_PHOTOS= (SELECT COUNT(DISTINCT(C.PHOTO_ID)) FROM COMMENTS C))
SELECT USERNAME, ID, (SELECT COUNT(PHOTO_ID) FROM COMMENTS WHERE COMMENTS.USER_ID=USERS.ID) NOC, 
CASE WHEN ID IN (SELECT ID FROM CTE1) THEN "NOT COMMENTED ON ANY PHOTOS #CELEBRETIES"
WHEN ID IN (SELECT ID FROM CTE2) THEN "COMMENTED ON EVERY PHOTO #BOT"
ELSE  "COMMENETED ON FEW PHOTOS #COMMON USER"
END AS STATUS FROM USERS
ORDER BY NOC DESC;

-- main query 

SELECT U.USERNAME, U.ID, COUNT(C.USER_ID) AS COMMENTED_ON_PHOTOS FROM USERS U
LEFT OUTER JOIN COMMENTS C  ON U.ID = C.USER_ID
GROUP BY U.USERNAME 
HAVING COMMENTED_ON_PHOTOS= (SELECT COUNT(DISTINCT(C.PHOTO_ID)) FROM COMMENTS C ) OR COMMENTED_ON_PHOTOS IS NOT NULL
ORDER BY COMMENTED_ON_PHOTOS DESC;

-- To count the number of people who have few comments,not commented,full comments.
WITH CTE1 AS 
(SELECT COUNT(*) FEW_COMMENTS FROM (SELECT U.USERNAME, U.ID, C.COMMENT_TEXT FROM COMMENTS C
LEFT OUTER JOIN USERS U ON U.ID=C.USER_ID   
GROUP BY U.ID)TABLE1),
CTE2 AS
(SELECT COUNT(*) NOT_COMMENTED FROM (SELECT U.USERNAME, U.ID, C.COMMENT_TEXT FROM USERS U 
LEFT OUTER JOIN COMMENTS C ON U.ID=C.USER_ID   
WHERE C.USER_ID IS NULL)TABLE2),
CTE3 AS 
(SELECT COUNT(*) FULL_COMMENT FROM (SELECT U.USERNAME, U.ID, C.COMMENT_TEXT FROM COMMENTS C
INNER JOIN USERS U ON U.ID=C.USER_ID   
GROUP BY C.USER_ID 
HAVING COUNT(*) = (SELECT COUNT(*) FROM PHOTOS))TABLE3)

SELECT CTE1.FEW_COMMENTS,CTE2.NOT_COMMENTED,CTE3.FULL_COMMENT FROM CTE1 INNER JOIN CTE2 INNER JOIN CTE3;

-- main query 2 

SELECT ID,USERNAME,(SELECT COUNT(PHOTO_ID) FROM COMMENTS WHERE COMMENTS.USER_ID=USERS.ID) AS NOC FROM USERS;

-- users who have commented few times. 
SELECT U.USERNAME, U.ID, COUNT(C.USER_ID) AS FEW_COMMENTS FROM COMMENTS C 
INNER JOIN USERS U ON C.USER_ID = U.ID
GROUP BY U.USERNAME 
HAVING FEW_COMMENTS <>(SELECT COUNT(DISTINCT(C.PHOTO_ID)) FROM COMMENTS C)
ORDER BY U.ID; 

-- Alternate 
SELECT username AS Username, COUNT(photo_id) AS FEW_COMMENTS
FROM comments
RIGHT JOIN users 
ON users.id = comments.user_id
GROUP BY username
HAVING FEW_COMMENTS NOT IN ((select COUNT(*) from photos), 0);

-- users who have commented atleast once but not on all. 

SELECT U.ID,USERNAME, COUNT(U.ID) AS atleast_once FROM USERS U
LEFT OUTER JOIN COMMENTS C ON U.ID=C.USER_ID   
GROUP BY U.ID
HAVING COUNT(U.ID)<>(SELECT COUNT(*) FROM PHOTOS)
ORDER BY COUNT(U.ID);

-- users who have commented only once.

SELECT U.ID,USERNAME, COUNT(U.ID) AS atleast_once FROM USERS U
LEFT OUTER JOIN COMMENTS C ON U.ID=C.USER_ID   
GROUP BY U.ID
HAVING COUNT(U.ID) NOT IN (SELECT COUNT(C.USER_ID) FROM COMMENTS)
ORDER BY COUNT(U.ID);

-- Total posts by user.

SELECT SUM(user_posts.total_posts_per_user)
FROM (SELECT users.username,COUNT(photos.image_url) AS total_posts_per_user
		FROM users
		JOIN photos ON users.id = photos.user_id
		GROUP BY users.id) AS user_posts;    
    
-- user ranking by postings higher to lower. 

SELECT users.username,COUNT(photos.image_url)
FROM users
JOIN photos ON users.id = photos.user_id
GROUP BY users.id
ORDER BY 2 DESC;  



-- get the all hash_tags comma seperated used on photo.  

Select pt.photo_id, group_concat(t.tag_name) from photo_tags pt
inner join tags t on pt.tag_id=t.id inner join photos p on t.id = p.id
group by pt.photo_id;

-- get the average tags that has been done on a photo. 

select ROUND((SELECT count(*) FROM tags)/(SELECT count(*) FROM photo_tags),2) as avg;

-- most liked post(highest number of likes).  
select l.photo_id, count(*) as cnt 
from likes l 
group by l.photo_id
order by cnt desc
limit 1;

-- first 5 days when most number of users register.  
select distinct(count(*)) total, date_format(created_at, '%Y %b %c') register_day from users
group by register_day
order by total desc
limit 5; 

--  alternative for who have never commented(using stored procedure). 
DROP PROCEDURE IF EXISTS P_ACTOR_DETAILS;
DELIMITER //
CREATE PROCEDURE P_ACTOR_DETAILS(I INT)
begin
IF (I=1) then
SELECT username,id FROM users WHERE id NOT IN(select distinct(user_id) from comments);
else
  IF (I=0) then
SELECT u.username, u.id FROM users u
INNER JOIN comments c ON c.user_id = u.id
GROUP BY u.id HAVING COUNT(c.user_id) = (select count(distinct(photo_id)) from comments);
else
SELECT U.USERNAME, U.ID, COUNT(C.USER_ID) AS FEW_COMMENTS FROM COMMENTS C 
INNER JOIN USERS U ON C.USER_ID = U.ID
GROUP BY U.USERNAME 
HAVING FEW_COMMENTS <>(SELECT COUNT(DISTINCT(C.PHOTO_ID)) FROM COMMENTS C);
end if;
end if ;
END//

DELIMITER ;
call p_actor_details(0);


-- 10th question using stored procedure. 
drop procedure if exists p_comment;
delimiter //
create procedure p_comment(n int)
begin
with cte as
(SELECT ID,USERNAME,(SELECT COUNT(PHOTO_ID) FROM COMMENTS WHERE COMMENTS.USER_ID=USERS.ID) AS Tot_comm FROM USERS)
select id,username,Tot_comm,
case 
 when Tot_comm =(SELECT COUNT(DISTINCT(C.PHOTO_ID)) FROM COMMENTS C) then  'commented on every photo'
  when Tot_comm =0 then 'not commented'
else 'commented on few photos'
end status
from cte where id=n;
end//
delimiter ;
call p_comment(88);


-- 5th alternative 
select * from
(select username,image_url,p.id as ph_id from users u 
inner join photos p on u.id=p.user_id) g1 
 inner join
(select count(*) counts,photo_id  from  likes l 
inner join photos p on p.id=l.photo_id
group by photo_id
order by counts desc
limit 1) g2
on g1.ph_id=g2.photo_id;

-- Users who have never liked or commented on any posts. 
SELECT USERNAME,ID FROM USERS 
WHERE USERS.ID NOT IN (SELECT USER_ID FROM LIKES) AND USERS.ID NOT IN (SELECT USER_ID FROM COMMENTS);

-- Find duplicates. 
with cte as 
(select *, row_number() over(partition by follower_id order by follower_id) rownum 
from follows) 
select * from cte src where rownum>1;

-- alternate to find duplicates.  
select follower_id,count(*)
from follows 
group by follower_id
having count(*) > 1;


