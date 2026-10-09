----------- DATA PREPARATION

-- Staging tables were created to preserve the raw data prior to any inspection or transformation.
select * into users_staging from users;
select * into tweets_staging from tweets;

--------- TABLE USERS-----------

----DATA QUALITY 

-- Verified the total row count (548).
select count(*) from users_staging;

-- Checked the ID column for duplicate values
select id,	
	   count(*) as duplicate_count
from users_staging
group by id
having count(*)> 1;

-- Missing Value Checks
declare @sql nvarchar(MAX) = '';

select @sql = @sql +
    'select ''' + COLUMN_NAME + ''' AS column_name, 
     count(*) - count(' + QUOTENAME(COLUMN_NAME) + ') AS null_count 
     from users_staging UNION ALL '
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'users_staging' ;

set @sql = LEFT(@sql, LEN(@sql) - LEN('UNION ALL '));
exec sp_executesql @sql;


----DATA TRANSFORMATION

-- Standardized inconsistent date/time formats in the "created_at" column and saved the result to "created_time".
alter table users_staging
    add created_time datetime2(0);
    go
    update users_staging
    set created_time =
        case
            when LEN(created_at) = 10
                then dateadd(second,CAST(created_at AS bigint), '1970-01-01')
            when LEN(created_at) = 30
                then CAST( SUBSTRING(created_at, 5, 6) + ' '
                            + RIGHT(created_at, 4) + ' '
                            + SUBSTRING(created_at, 12, 8) as datetime2(0)         )
        end;

-- Converted values in the "utc_offset" column from seconds to hours and saved them to "utc_offset_hours".
alter table users_staging
add utc_offset_hours int;
go
update users_staging
set utc_offset_hours =utc_offset/3600


-- Removed profile-related columns that are not required for the analysis.
alter table users_staging
drop column url,id_str,created_at, utc_offset,geo_enabled, follow_request_sent, following, has_extended_profile,is_translator,notifications,
			profile_background_color, profile_background_image_url, profile_background_image_url_https, profile_background_tile, 
			profile_banner_url,profile_image_url,profile_image_url_https,profile_link_color,profile_sidebar_border_color,
			profile_sidebar_fill_color,profile_text_color, profile_use_background_image,protected,
			contributors_enabled, default_profile_image;


--------- TABLE TWEETS-----------

----DATA QUALITY 

-- Verified the total row count (1243370).
select count(*) from tweets_staging;

-- Checked the ID column for duplicate values
select id,
	   count(*) as duplicate_count
from tweets_staging
group by id
having count(*) >1;

-- Missing Value Checks
declare @sql nvarchar(MAX) = '';

select @sql = @sql +
    'select ''' + COLUMN_NAME + ''' AS column_name, 
     count(*) - count(' + QUOTENAME(COLUMN_NAME) + ') AS null_count 
     from tweets_staging UNION ALL '
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'tweets_staging' ;

set @sql = LEFT(@sql, LEN(@sql) - LEN('UNION ALL '));
exec sp_executesql @sql;

----DATA TRANSFORMATION 

-- Stripped HTML tags from the "source" column and saved the extracted source information to "source_clean".
alter table tweets_staging
add source_clean nvarchar(MAX);
go
update tweets_staging
set source_clean = 
       SUBSTRING( source,
                 CHARINDEX('>', source) + 1,
                 CHARINDEX('<', source, CHARINDEX('>', source)) - CHARINDEX('>', source) - 1) ;

-- Grouped values in the "source_clean" column into suitable categories for analysis and saved them to "source_group".

alter table tweets_staging
add source_group nvarchar(MAX);
go
update tweets_staging
set source_group = case
						when source_clean in (
							'Twitter Web Client',
							'Twitter for iPhone',
							'Twitter for iPad',
							'Twitter for Android',
							'iOS',
							'Twitter Lite',
							'Twitter for Websites',
							'Twitter for BlackBerry®',
							'Twitter for BlackBerry',
							'Mobile Web',
							'Camera on iOS',
							'Twitter for Mac',
							'Photos on iOS'
														) then 'Native Clients'
						when source_clean in (
							'TweetDeck',
							'Hootsuite',
							'Buffer',
							'Sprout Social',
							'Percolate',
							'Fireside Publishing',
							'Gain App'
														) then 'Management Tools'
						when source_clean in (
							'Facebook',
							'Instagram',
							'twitterfeed',
							'Twitpic',
							'Google',
							'GovDelivery'
														) then 'Cross-Platform Sources'
						end 

-- Identified tweets starting with "RT @" in the "text" column as retweets, binary encoding them as 1 in the "retweet" column and 0 otherwise.
alter table tweets_staging
add retweet bit default 0;
go
update tweets_staging
set retweet = case when text LIKE 'RT @%' then 1 else 0 end;

-- Identified tweets containing an "in_reply_to_status_id" value as replies, binary encoding them as 1 in the "reply" column and 0 otherwise.
alter table tweets_staging
add reply bit default 0;
go
update tweets_staging
set reply= case when in_reply_to_status_id is not null then 1 else 0 end;

-- Classified tweets not identified as a reply, retweet, or quote as original tweets, binary encoding them as 1 in the "original_tweet" column and 0 otherwise.
alter table tweets_staging 
add original_tweet bit default 0;
go
update tweets_staging
set original_tweet = case when retweet=0 and reply=0 and is_quote_status=0 then 1 else 0 end

-- Extracted hashtags from the "entities" JSON column, lowercased, deduplicated, and saved them as a comma-separated string in the "hashtags" column.
alter table tweets_staging
add hashtags nvarchar(MAX);
go
update t
set hashtags = (
    select STRING_AGG(d.hashtag, ',')
    from (
        select distinct lower(h.hashtag) as hashtag
        from openjson(t.entities, '$.hashtags')
             with (hashtag nvarchar(100) '$.text') as h
    ) as d
)
from tweets_staging as t;

-- Identified tweets containing hashtags, binary encoding them as 1 in the "using_hashtag" column and 0 otherwise
alter table tweets_staging
add using_hashtag bit default 0;
go
update tweets_staging
set using_hashtag = case when hashtags is not null then 1 else 0 end;


-- Removed columns that are not required for the analysis.
alter table tweets_staging
drop column source,geo,contributors,coordinates, favorited, id_str,place, retweeted,truncated,possibly_sensitive,
			withheld_copyright,withheld_in_countries,withheld_scope,in_reply_to_status_id_str,in_reply_to_user_id_str
