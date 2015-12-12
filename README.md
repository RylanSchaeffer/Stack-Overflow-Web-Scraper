# Stack-Overflow-Web-Scraper
STA141 Project 6

"scrape_stack_overflow" accepts a Stack Overflow tag (e.g. "r", "javascript") and either a number of pages or number of questions to scrape. The script then extracts summary information from each question (e.g. user, date, current views, current votes) up to to specified number of pages/questions.

"scrape_all_posts" accepts a list of Stack Overflow question urls (which can be gathered using scrape_stack_overflow) and extracts the question, answers and comments from each post's page, as well as summary information (e.g. user, date, text).








Specific Instructions (currently available online at http://eeyore.ucdavis.edu/stat141/Hws/stackoverflow.html)

Part 1 - Scraping the Summaries of the Posts

Process the current summary page of posts, starting with the first page of results. For each post, extract information about

    who posted it,
    when it was posted,
    the title of the post
    the reputation level of the poster,
    the current number of views for the post,
    the current number of answers for the post,
    the vote "score" for the post,
    the URL for the page with the post, answers and comments,
    the id (a number) uniquely identifying the post.

Obtain the URL for the "next" page listing posts
    
    repeat steps 1, 2, 3

Of course, you need to write functions to do the different steps. Your top-level function should allow the caller specify which forum/top-level tag (e.g., r, javascript, d3.js) to scrape. It should also allow the caller to specify a limit on the number of posts to process, either the number of pages or the total number of posts. If this is not specified, it should process all of the pages for this topic/tag.

The function should return a data frame, with a row for each post. 

Part 2 - Scraping the Posts, Answers and Comments

This part is optional, but I strongly encourage you to do it in order to learn how to scrape data from HTML documents.

Next, write a function that processes the actual page for an individual post, i.e., the page containing the post, its answers and comments. The function should extract and combine information for the post, each answer and each comment. For each of these "entries", we want

    the type of entry (post, answer, comment)
    the user,
    userid,
    date,
    user's reputation,
    the score/votes for this entry,
    the HTML content as a string for this entry,
    the identifier of the "parent" entry, i.e., which entry this is a response to - a comment to an answer, or an answer to a post,
    the unique identifier for the overall post.

Again, create a data frame to store all of the posts, questions and comments.