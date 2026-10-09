# CONGRESSIONAL TWITTER (X) DATA ANALYSIS
*Capstone project completed as part of the [Learn SQL Basics for Data Science Specialization](https://www.coursera.org/specializations/learn-sql-basics-data-science), offered by the University of California, Davis on Coursera.*

I completed all three courses in the specialization. [View my certificate](https://coursera.org/share/ca01aacf9c45345762da725015e4e44b).

## Project Overview
This project is a comprehensive SQL-based analysis of Twitter (X) activity among members of the U.S. Congress using a large-scale social media dataset. The objective is to examine how the platform was utilized as a communication channel and to evaluate user behavior through data-driven analytical methods. The project involved preparing and transforming raw data into an analysis-ready structure, followed by the development of behavioral and performance-oriented metrics using SQL. The resulting insights were used to assess patterns in platform adoption, content creation practices, and audience interaction from a broader analytical perspective.

## Dataset Information
This project uses a Twitter (X) dataset provided through the SQL for Data Science Capstone Project course on Coursera, offered by the University of California, Davis.

The dataset contains account-level and tweet-level data for 548 members of the U.S. Congress, covering the period from April 27, 2007, to June 6, 2017. In total, it includes more than 1.24 million tweets, providing a comprehensive view of congressional activity on the platform during the study period.

## Tools 
- Microsoft SQL Server (T-SQL)

## SQL Concepts Demonstrated 

- SELECT, WHERE, GROUP BY and ORDER BY
- Aggregate Functions: COUNT(), SUM(), AVG()
- JOINs
- Common Table Expressions (CTEs)
- Views and Temporary Tables
- Window Functions: RANK(), ROW_NUMBER(), LAG(), PERCENT_RANK(), SUM() OVER()
- Percentile Analysis: PERCENTILE_CONT()
- CASE WHEN Statements
- Date and Time Functions: DATEPART(), DATETRUNC(), YEAR(), DATEADD()
- String Functions: TRIM(), SUBSTRING(), CHARINDEX(), STRING_SPLIT(), STRING_AGG()
- Type Casting: CAST()
- NULL Handling: IS NULL, IS NOT NULL
- JSON Data Extraction with OPENJSON()
- Conditional Calculations and Percentage Analysis
- Data Cleaning and Data Transformation
- Data Validation
- Correlation Analysis (Spearman's Rank Correlation)

 ## Questions

1. Platform Adoption  
How did the number of members of Congress joining Twitter change between 2008 and 2017?

2. Tweet Volume  
How was the number of tweets posted by members of Congress distributed over time?

3. Most Active Users  
a)Which members of Congress had the highest monthly tweet volume?  
b)In how many months did each member rank among the top 5 most active users?

4. Tweet Type  
What was the dominant tweet type for each member, and how were members distributed across these behavioral patterns?

5. Language Analysis  
a)How were tweets distributed across languages?  
b)Which languages were most commonly used?

6. Tweet Source  
a)How were tweets distributed across different tweet sources?  
b)How did engagement vary across different tweet sources in 2016 and 2017?

7. Hashtag Usage  
a)Which hashtags were the most used in each month?  
b)Which hashtags most frequently ranked among the top 3 hashtags of the month?

8. Hashtag Usage and Engagement  
a)Is hashtag usage associated with differences in tweet engagement?  
b)Do hashtag tweets tend to rank higher in engagement than non-hashtag tweets posted by the same member across all years and from 2016 onwards?

9. Follower Count  
Who were the 10 members of Congress with the highest follower counts, and were any of these accounts unverified?

10. Follower Count vs. Average Engagement Per Tweet  
Is there a relationship between follower count and average engagement per tweet among members of Congress?


## Key Findings 

- Twitter adoption accelerated rapidly between 2008 and 2013, when 312 of 548 congressional members (57%) joined the platform. Adoption peaked in 2009 with 123 new accounts.

- Twitter activity showed a clear upward trend over the study period, reaching its highest levels in 2016 and 2017. The most active month was March 2017, when 531 congressional members generated 33,086 original tweets, corresponding to an average of 62.31 tweets per member.

<img width="410" height="401" alt="SSMS_GB2fwN7AsY" src="https://github.com/user-attachments/assets/1d5dfcba-acf4-44e5-b688-dae831d71246" />

- Original tweets were the dominant communication format. For 96.15% of members, original tweets represented the most frequently used tweet type, while retweets and replies were dominant for only a small minority.

<img width="400" height="140" alt="SSMS_u5R0hXi9a8" src="https://github.com/user-attachments/assets/0ca09c31-bcd2-4cc4-8cc5-6e0e45e33427" />

- English overwhelmingly dominated congressional Twitter activity, accounting for 98.74% of all non-retweet tweets.

- Native Twitter clients generated 69.59% of all tweets, compared to 27.18% for management tools and 3.23% for cross-platform sources.

- Hashtag usage showed only a limited association with engagement. While hashtag tweets ranked higher for 71.43% of members across the full study period, this share declined to 59.15% after 2016, suggesting that the engagement advantage of hashtags weakened over time.
  
Full Study Period   
<img width="400" height="140" alt="SSMS_1BGFfhS6Q7" src="https://github.com/user-attachments/assets/8e8aef07-7bb3-4925-a96a-9212e0af924a" />

2016 and Later   
<img width="400" height="140" alt="SSMS_cbxDIAo4SK" src="https://github.com/user-attachments/assets/9ff97bfd-57fa-401b-b8fc-3f1be910906b" />

- The most consistently used hashtags were #tcot, #obamacare, and #gop, suggesting continued discussion around recurring political topics throughout the study period.

- A moderate positive relationship was observed between follower count and average engagement per tweet (Spearman's ρ ≈ 0.58), indicating that accounts with larger audiences tended to receive more engagement on average.
<img width="400" height="140" alt="SSMS_6TOt4Shjhq" src="https://github.com/user-attachments/assets/dfbb8926-1b37-4615-b6fd-4121b7bc46e2" />











