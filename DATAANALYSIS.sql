/*
	CONGRESS TWITTER DATA ANALYSIS (SQL Server / T-SQL)
	Data: Twitter dataset containing U.S. Congress members and their tweets
	Coverage: 2007-04-27 to 2017-06-06


	Metrics
	- Percentage Change = (New Value - Old Value) / Old Value * 100

	- Total Engagement = Favorite Count + Retweet Count

	- Average Engagement per Tweet = Total Engagement / Tweet Count


	Scope and Methodological Notes
	1. Tweet scope
	Retweets carry the engagement counts (favorites and retweets) of the original author's tweet rather than of the member who reposted it. 
	Including them would attribute engagement to members for content they did not write. Therefore, analyses of engagement or content were restricted as follows:
	- Original tweets only (original_tweet = 1): Q2, Q3, Q8
	- All tweets except retweets (Retweet = 0): Q5, Q6, Q7, Q10
	- All tweets, including retweets: Q4  

	2. Minimum sample thresholds
	Thresholds were applied to prevent members with very few tweets from distorting averages and rank comparisons:
	- Q8b: members with at least 30 hashtag and 30 non-hashtag original tweets
	- Q10: members with more than 50 tweets

	3. Partial year
	The dataset ends on 2017-06-06, so 2017 covers only about five months. 
	Year-level comparisons involving 2017 (Q1, Q6b) and the final month in Q2 should be interpreted with this in mind.
*/


------QUESTIONS

---Q1: Platform Adoption
--How did the number of members of Congress joining Twitter change between 2008 and 2017?

--Note: Year-over-year growth percentages should be interpreted with caution in the early years of the period. Because the cumulative base is small, even a modest
--number of new members produces a disproportionately high percentage (base effect). The growth rate should therefore be evaluated together with new_members.
with yearly_members  as
(	select datepart(year,created_time) as join_year,
		   count(*) as new_members
	from users_staging
	group by datepart(year,created_time)
),cumulative as
(	
select *,
		   sum(new_members) over(order by join_year) as total_members
	from yearly_members
),with_previous as
(
select *,
		lag(total_members) over (order by join_year) as last_year_total
 from cumulative
 )
 select join_year,
		new_members,
		total_members,
		cast((total_members-last_year_total)*100.0/last_year_total as decimal(10,2)) as total_growth_pct
 from with_previous
 where join_year between 2008 and 2017 ;

/*
	RESULTS:
	Twitter adoption among members peaked in 2009 (123 new members), followed by 2011 (92) and 2013 (72).
	The 2008-2011 period accounts for 312 of 548 members (about 57%). 
*/

---Q2: Tweet Volume
--How was the number of tweets posted by members of Congress distributed over time?

with monthly_tweet
as
(
select 
	   cast (datetrunc(month,created_at) as date) as month_start,
	   count(*) as tweet_count,
	   count(distinct user_id) as distinct_member
from tweets_staging
where original_tweet = 1
group by datetrunc(month,created_at)
)
select month_start,
	   tweet_count,
	   distinct_member,
	   cast(tweet_count/(distinct_member*1.0) as decimal(10,2) )as tweets_per_member
from monthly_tweet
order by tweets_per_member desc;

/*
	RESULTS:
	All 10 of the highest-activity months (by tweets per member) occurred in 2016 and 2017, with the peak in March 2017 
	(33,086 original tweets from 531 members, 62.31 tweets per member).
	Activity increased steadily over time: monthly tweets per member ranged roughly 9-24 in 2009-2010, 22-41 in 2013-2014, 
	31-43 in 2015, 34-54 in 2016, and 46-62 in January-May 2017.
	The number of active members per month also grew, from 1-4 in 2008 to 531 in 2017, so the increase reflects both wider participation and higher per-member activity.
	June 2017 (8.04 tweets per member) covers only the first days of the month and is not comparable to full months.
	Therefore, 2016 onwards was used as the reference period in Q6b and Q8b.
*/


---Q3: Most Active Users
--a)Which members of Congress had the highest monthly tweet volume?
go
create view [Monthly_Top_5_Member] as
with monthly_member
as
(
select user_id,
	   count(*) as tweet_count,
	   cast (datetrunc(month,created_at) as date) as month_start
from tweets_staging
where original_tweet = 1
group by user_id,datetrunc(month,created_at)
),
ranking
as
(
select *,
		RANK() over (partition by month_start order by tweet_count desc) as rank_
from monthly_member 
)
select u.name,
	   r.user_id,
	   r.tweet_count,
	   r.month_start,
	   r.rank_
from ranking r left join users_staging u
on r.user_id = u.id
where rank_<=5
go
select * from Monthly_Top_5_Member
order by month_start asc;

--b)In how many months did each member rank among the top 5 most active users?
select user_id,name,
	   count(user_id) as rank_count
from Monthly_Top_5_Member
group by user_id,name
order by rank_count desc;

/*
	RESULTS:
	190 different accounts ranked among the top 5 in at least one month. Henry McMaster and Kenny Marchant were the most consistent, 
	each ranking in 16 months, followed by Rob Wittman and Steve Bullock with 11 months each.
	Only 9 accounts reached the top 5 in 9 or more months, while 159 of the 190 (84%) did so in 4 months or fewer and 78 (41%) in a single month.
	The top-5 positions were therefore spread across many accounts rather than dominated by one or two.
*/


---Q4: Tweet Type:
--What was the dominant tweet type for each member, and how were members distributed across these behavioral patterns?

--Note: Tweet types were classified into mutually exclusive categories. 
--When a tweet had both Reply and Quote characteristics, it was classified as a Quote tweet. Retweets were treated as a separate priority category.
with tweet_type_counts
as
(
	select user_id,
		   screen_name,
		   count(*) as total_tweets,
		   count(case when is_quote_status = 1 and Retweet=0 then 1 end ) as total_quote,
		   count(case when Retweet = 1 then 1 end ) as total_retweet,
		   count(case when Reply = 1 and Retweet=0 and is_quote_status=0 then 1 end ) as total_reply,
		   count(case when original_tweet = 1 then 1 end ) as total_original
	from tweets_staging 
	group by user_id, screen_name
),tweet_type_perc as
(
	select screen_name,
		   total_tweets,
		   cast((total_quote/(total_tweets*1.0)*100) as decimal(10,1)) as perc_quote,
   		   cast((total_retweet/(total_tweets*1.0)*100) as decimal(10,1))as perc_retweet,
		   cast((total_reply/(total_tweets*1.0)*100) as decimal(10,1))as perc_reply,
		   cast((total_original/(total_tweets*1.0)*100) as decimal(10,1)) as perc_original
	from tweet_type_counts
), dominant_tweet_type as
(
select  case GREATEST(perc_quote,perc_retweet,perc_reply,perc_original)
			 when perc_quote then 'quote'
			 when perc_retweet then 'retweet'
			 when perc_reply then 'reply'
			 when perc_original then 'original'
		end as most_using_type
from tweet_type_perc
)
select most_using_type,
	   count(*) as member_count,
	   cast(count(*)*100.0 / sum(count(*)) over() as decimal(10,2)) as member_perc
from dominant_tweet_type
group by most_using_type

/*
	RESULTS:
	Original tweets were the dominant tweet type for 96.15% of members (524 members).
	Retweets (3.12%) and replies (0.73%) were dominant for only a small number of members, 
	indicating that most members primarily used Twitter to publish original content rather than reposting or replying to others.
*/


---Q5: Language Analysis
--a)How were tweets distributed across languages?
select lang,
	   count(*) as tweet_count
from tweets_staging
where Retweet=0
group by lang
order by count(*) desc

--b)Which languages were most commonly used?
select 
	    case  when lang = 'en' then 'English' else 'Other Language'
			end as Language_group,
		count(*) as tweet_count,
		cast (count(*)*100.0 / sum(count(*)) over () as decimal(10,2)) as perc

from tweets_staging
where Retweet=0
group by case  when lang = 'en' then 'English' else 'Other Language' end;

/*
	RESULTS:
	Language distribution analysis shows that 98.74% of non-retweet tweets  were posted in English, while all other languages combined accounted for only 1.26% of the dataset.
	The five most common language categories were English, undefined (und), Spanish, French, and Indonesian, although each non-English category represented only a marginal share of total tweet volume. 
	These findings highlight the near-exclusive use of English across congressional Twitter activity.
*/


---Q6: Tweet Source
--a)How were tweets distributed across different tweet sources?
select source_group,
	   count(*) as tweet_count
from tweets_staging
where source_group is not null and Retweet=0
group by source_group ;

--b)How did engagement vary across different tweet sources in 2016 and 2017?

--Note: Since engagement metrics exhibit a skewed distribution driven by highly engaging tweets, both mean and median values are presented.
--Evaluations should consider both measures to obtain a more balanced interpretation of engagement patterns.
go 
create view [Tweet_Source_Enga] as
with tweet_med
as
(
select source_group,
	   user_id,
	   favorite_count,
	   retweet_count,
	   Year(created_at) as year,
	   PERCENTILE_CONT(0.5) within group(order by favorite_count) over(partition by Year(created_at)) as med_fav,
	   PERCENTILE_CONT(0.5) within group(order by favorite_count) over(partition by source_group,Year(created_at)) as med_source_fav,
	   PERCENTILE_CONT(0.5) within group(order by retweet_count+ favorite_count) over(partition by Year(created_at)) as med_enga,
	   PERCENTILE_CONT(0.5) within group(order by retweet_count+ favorite_count) over(partition by source_group, Year(created_at)) as med_source_enga
from tweets_staging
where source_group is not null
	  and Retweet=0
)
select year,
	   source_group,
	   count(*) as tweet_count,
	   count(distinct user_id) as distinct_user,
	   sum(favorite_count) as total_fav,
	   cast ((count(*) /(count(distinct user_id)*1.0)) as decimal(10,2)) as avg_tweets_per_user,
	   cast(avg(favorite_count*1.0) as decimal(10,2)) as favs_per_tweet,
	   med_fav,
	   med_source_fav,
	   cast (avg((favorite_count+retweet_count)*1.0) as decimal(10,2)) as engagement_per_tweet,
	   med_enga,
	   med_source_enga
from tweet_med
group by source_group, med_fav,med_source_fav, med_enga,med_source_enga,year
go 

select * from Tweet_Source_Enga
where year= 2016;

select * from Tweet_Source_Enga
where year= 2017;

/*
	RESULTS: 
	a)Most tweets were posted through Native Clients, accounting for 69.59% of total tweet volume. Management Tools represented 27.18% of tweets, while Cross-Platform Sources contributed only 3.23%. 
	This distribution suggests that congressional Twitter activity was primarily driven by native Twitter clients rather than third-party management or cross-platform tools.

	b)Average metrics indicate that tweets posted through Native Clients tended to receive higher engagement than those published through other source groups. 
	In 2017, the average number of favorites per tweet was 973.86 for Native Clients, compared with 388.72 for Management Tools and 38.44 for Cross-Platform Sources.
	Similarly, average engagement per tweet was 1263.90, 537.86, and 47.24, respectively. However, median values reveal that these differences were considerably smaller than the averages suggest.
	Source-level median favorite counts were 7, 19, and 24, while median engagement values were 9, 26, and 33 for Cross-Platform Sources, Management Tools, and Native Clients, respectively. 
	This pattern suggests that a relatively small number of highly engaging tweets may have disproportionately increased the mean values, resulting in a skewed distribution.
	Nevertheless, the consistent ranking observed across both mean and median measures indicates a potential relationship between tweet source type and engagement outcomes. 
	These findings should be interpreted as evidence of association rather than causation.
*/

---Q7: Hashtag Usage
--a)Which hashtags were the most used in each month?
go
create view [Monthly_Top_3_Hashtag] as 
with monthly_hashtags
as
(
select 	cast (datetrunc(month,created_at) as date) as month_start,
	    Trim(h.value) as Hashtag,
		count(*) as hashtag_count
from tweets_staging
cross apply string_split(tweets_staging.Hashtags, ',') as h
where retweet=0 
group by datetrunc(month,created_at),Trim(h.value)
) ,ranked
as
(
select* ,
	  row_number() over(partition by month_start order by hashtag_count desc) as hashtag_rank
from monthly_hashtags
)
select * from ranked
where hashtag_rank<=3
go 
select * from Monthly_Top_3_Hashtag;

--b)Which hashtags most frequently ranked among the top 3 hashtags of the month?
select hashtag,
	   count(*) as hashtag_count
from Monthly_Top_3_Hashtag
group by Hashtag
order by hashtag_count desc;

/*
	RESULTS:  
	`tcot` appeared most frequently among the monthly top three hashtags, ranking in the top three in 48 months.
	It was followed by `obamacare` (21 months) and `gop` (16 months). 
	These findings indicate that these hashtags repeatedly ranked among the most frequently used hashtags across the study period, 
	potentially reflecting sustained interest in the political topics they represent.
*/

---Q8: Hashtag Usage and Engagement
--a)Is hashtag usage associated with differences in tweet engagement?
with hashtag_users_med as
( select id,
		 using_hashtag,
		 favorite_count,
		 retweet_count,
		 PERCENTILE_CONT(0.5) within group (order by favorite_count + retweet_count) over (partition by using_hashtag) as med_enga,
		 PERCENTILE_CONT(0.90) within group (order by favorite_count + retweet_count) over (partition by using_hashtag) as p90_enga,
		 PERCENTILE_CONT(0.95) within group (order by favorite_count + retweet_count) over (partition by using_hashtag) as p95_enga,
		 PERCENTILE_CONT(0.99) within group (order by favorite_count + retweet_count) over (partition by using_hashtag) as p99_enga
from tweets_staging
where original_tweet=1
) 
select 
	   case when using_hashtag = 1 then 'Hashtag used' else 'No Hashtag' end as hashtag_status, 
	   count(*) as tweet_count,
	   sum(cast(retweet_count as bigint) + cast(favorite_count as bigint)) as enga,
	   med_enga,
	   p90_enga,
	   p95_enga,
	   p99_enga,
	   (sum(cast(retweet_count as bigint) + cast(favorite_count as bigint))) / (count(*)*1.0) as avg_enga
from hashtag_users_med
group by using_hashtag,med_enga, p90_enga,p95_enga,p99_enga;

/*
	RESULTS:
	Original tweets with and without hashtags were compared using average, median, and percentile engagement metrics.
	Median engagement was similar (7 vs. 6), while non-hashtag tweets had substantially higher P99 engagement (9,772.88 vs. 1,304.24).
	The higher average engagement for non-hashtag tweets (562.94 vs. 149.36) therefore appears to be driven largely 
	by a small number of highly engaged tweets rather than a general difference across the distribution.
*/

--b)Do hashtag tweets tend to rank higher in engagement than non-hashtag tweets posted by the same member across all years and from 2016 onwards?

--Note: The analysis was restricted to tweets from 2016 onwards, the most active years of Twitter usage in the dataset. Members with at least 30 hashtag and 30 non-hashtag original tweets were included (497 members).
--The average engagement rank of each member's hashtag tweets was compared with the average rank of their non-hashtag tweets.

--All years
with tweet_rank as
(
select user_id,
	   using_hashtag,
	   PERCENT_RANK() over (partition by user_id order by cast(favorite_count as bigint) + cast(retweet_count as bigint)) as enga_perc_rank
from tweets_staging
where original_tweet=1 
),member_rank_avg as
(
select  user_id,
		avg(case when using_hashtag=1 then enga_perc_rank end) as avg_hashtag_enga_rank,
		avg(case when using_hashtag=0 then enga_perc_rank end) as avg_no_hashtag_enga_rank
from tweet_rank 
group by user_id
having  count(case when using_hashtag=1 then 1 end) >=30 
		and count(case when using_hashtag=0 then 1 end) >=30 
),hashtags_ahead as
(
select *,
	   case when avg_hashtag_enga_rank > avg_no_hashtag_enga_rank then 'Hashtag Ahead' else 'Hashtag Behind' end as ahead_status,
	   avg_hashtag_enga_rank - avg_no_hashtag_enga_rank as rank_diff
from member_rank_avg
)
select ahead_status,
	   count(*) as member_count ,
	   cast (count(*)*100.0 / sum(count(*)) over () as decimal(10,2)) as perc,
	   cast(avg(rank_diff)*100 as decimal(10,2)) as avg_rank_diff_pts
from hashtags_ahead 
group by ahead_status;

--2016 onwards
with tweet_rank as
(
select user_id,
	   using_hashtag,
	   PERCENT_RANK() over (partition by user_id order by cast(favorite_count as bigint) + cast(retweet_count as bigint)) as enga_perc_rank
from tweets_staging
where original_tweet=1 and created_at >='2016-01-01'
),member_rank_avg as
(
select  user_id,
		avg(case when using_hashtag=1 then enga_perc_rank end) as avg_hashtag_enga_rank,
		avg(case when using_hashtag=0 then enga_perc_rank end) as avg_no_hashtag_enga_rank
from tweet_rank 
group by user_id
having  count(case when using_hashtag=1 then 1 end) >=30 
		and count(case when using_hashtag=0 then 1 end) >=30 
),hashtags_ahead as
(
select *,
	   case when avg_hashtag_enga_rank > avg_no_hashtag_enga_rank then 'Hashtag Ahead' else 'Hashtag Behind' end as ahead_status,
	   avg_hashtag_enga_rank - avg_no_hashtag_enga_rank as rank_diff
from member_rank_avg
)
select ahead_status,
	   count(*) as member_count ,
	   cast (count(*)*100.0 / sum(count(*)) over () as decimal(10,2)) as perc,
	   cast(avg(rank_diff)*100 as decimal(10,2)) as avg_rank_diff_pts
from hashtags_ahead 
group by ahead_status;

/*
	RESULTS: 
	Each member's original tweets with and without hashtags were compared by their engagement (favorites + retweets) percentile rank within that member's own tweets. This method removes the effect of account size.

	All years (532 members):
	- In 71.43% (380 members), tweets with hashtags ranked higher; average difference +9.93 points.
	- In 28.57% (152 members), tweets without hashtags ranked higher; average difference -6.33 points.
	- Weighted average difference across all members: approximately +5.3 points.

	2016 and later (497 members):
	- In 59.15% (294 members), tweets with hashtags ranked higher; average difference +7.08 points.
	- In 40.85% (203 members), tweets without hashtags ranked higher; average difference -6.00 points.
	- Weighted average difference across all members: approximately +1.7 points.

	Interpretation:
	Tweets with hashtags show a slight within-member advantage, but this advantage shrinks noticeably after 2016 (71% -> 59%; +5.3 -> +1.7 points).
	The direction is positive in both analyses, but the practical effect is small. The fact that median engagement was similar in both groups in 8a also supports the impression that hashtags have no clear effect.
*/


---Q9: Follower Count
--Who were the 10 members of Congress with the highest follower counts, and were any of these accounts unverified?
select top 10 id,
		   name,
		   followers_count,
		   case 
				when verified = 1 then 'yes' else 'no' 
				end as Verified 
from users_staging
order by followers_count desc;

/*
	RESULTS:
	All of the top 10 accounts are verified.
*/

---Q10: Follower Count vs. Average Engagement Per Tweet
--Is there a relationship between follower count and average engagement per tweet among members of Congress?

--Note: Spearman's rank correlation was selected to examine the monotonic relationship between follower count and average engagement per tweet. 
--The skewed distributions made this non-parametric, rank-based method appropriate.
--Among the 540 members, only four follower-count values were shared by two members each, indicating that ties in follower counts were limited.

with engagement as
(
select user_id,
	   screen_name,
	   count(*) as tweet_count,
	   sum(cast(favorite_count as bigint)) as total_fav,
	   sum(cast(retweet_count as bigint)) as total_rt,
	   sum(cast(favorite_count as bigint) + cast(retweet_count as bigint)) as total_enga
from tweets_staging
where Retweet = 0 
group by user_id,screen_name
), engagement_rate as
(
select  e.screen_name,
		u.followers_count,
		e.tweet_count,
		e.total_enga,
		(e.total_enga) / (e.tweet_count*1.0) as avg_enga
from engagement e inner join users_staging u 
on e.user_id = u.id
where tweet_count > 50
)
select * into #Engarate
from engagement_rate;

with engagement_rank as
(
select  *,
	    rank () over (order by avg_enga desc) as avg_enga_rank,
		rank () over (order by followers_count desc) as followers_rank
from #Engarate
) ,calculate as
( 
select  sum(square(followers_rank - avg_enga_rank)) as total_difference,
		count(*) as total_user
from engagement_rank
)
select  1- ((6*total_difference)/ (total_user * (square(total_user)-1))) as spearman_rho
from calculate;

/*
	RESULTS: 
	A moderate positive relationship was observed between follower count and average engagement per tweet (Spearman's ρ ≈ 0.58). 
	This finding suggests that accounts with larger follower bases may tend to receive higher levels of engagement on average.
	However, the results should be interpreted as an association rather than a causal relationship. 
	In addition, the analysis was based on raw engagement per tweet rather than engagement rates, meaning that performance was not normalized relative to audience size.
*/ 