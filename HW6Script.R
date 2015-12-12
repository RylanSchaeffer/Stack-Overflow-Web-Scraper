library(xml2)
library(knitr)

scrape_id = function(nodes){
  
  id = sapply(nodes, function(node){
    matches = xml_find_all(node, "./@id")
    if (length(matches) == 0){
      return(NA)
    }
    xml_text(matches)
  })
  
  as.numeric(gsub("question-summary-([0-9]*)", "\\1", unname(unlist(id))))
}

scrape_date = function(nodes){
  date = sapply(nodes, function(node){
    matches = xml_find_all(node, ".//div[@class = 'user-action-time']//span/@title")
    if (length(matches) == 0){
      return(NA)
    }
    xml_text(matches[1])
  })
  
  as.POSIXct(date)
}

scrape_tags = function(nodes){
  tags = sapply(nodes, function(node){
    matches = xml_find_all(node, ".//div[contains(@class, 'tags') and contains(@class, 't-r')]/@class")
    if (length(matches) == 0){
      return(NA)
    }
    xml_text(matches[1])
  })
  
  gsub(" t-" , "; ", gsub("tags t-", "", tags))
}

scrape_titles = function(nodes){
  title = sapply(nodes, function(node){
    matches = xml_find_all(node, ".//div[@class = 'summary']/h3/a/text()")
    if (length(matches) == 0){
      return(NA)
    }
    xml_text(matches[1])
  })
}

scrape_urls = function(nodes){
  url = sapply(nodes, function(node){
    matches = xml_find_all(node, ".//div[@class = 'summary']/h3/a/@href")
    if (length(matches) == 0){
      return(NA)
    }
    xml_text(matches[1])
  })
  
  paste("https://stackoverflow.com", url, sep = "")
}

scrape_views = function(nodes){
  views = sapply(nodes, function(node){
    matches = xml_find_all(node, ".//div[@class = 'views ']")
    if (length(matches) == 0){
      return(NA)
    }
    xml_text(matches[1])
  })
  
  as.numeric(gsub("\r\n *([0-9]*) views\r\n", "\\1", views))
}

scrape_votes = function(nodes){
  sapply(nodes, function(node){
    matches = xml_find_all(node, ".//span[@class = 'vote-count-post ']")
    if (length(matches) == 0){
      return(NA)
    }
    xml_text(matches[1])
  })
}

scrape_replies = function(nodes){
  answers = sapply(nodes, function(node){
    matches = xml_find_all(node, ".//div[contains(@class, 'status')]")
    if (length(matches) == 0){
      return(NA)
    }
    xml_text(matches[1])
  })
  answers = as.numeric(gsub("\r\n *([0-9]*)answer(s?)\r\n *", "\\1", answers))
}

scrape_users = function(nodes){
  user = sapply(nodes, function(node){
    matches = xml_find_all(node, ".//div[@class = 'user-details']")
    if (length(matches) == 0){
      return(NA)
    }
    xml_text(matches[1])
  })
  
  sub("\r\n.*", "", sub("\r\n *", "", user))
}

scrape_reputations = function(nodes){
  sapply(nodes, function(node){
    matches = xml_find_all(node, ".//span[@class = 'reputation-score']")
    if (length(matches) == 0){
      return(NA)
    }
    xml_text(matches[1])
  })
}

scrape_nexturl = function(html){
  next_url = xml_text(xml_find_one(html, "//div[@class = 'pager fl']/a[@rel = 'next']/@href"))
  paste("https://stackoverflow.com", next_url, sep = "")
}

scrape_summaries = function(url){
  
  # parse html document from URL
  html = read_html(url)
  
  summaries = xml_find_all(html, "//div[@class = 'question-summary']")

  id = scrape_id(summaries)
  
  date = scrape_date(summaries)
  
  tags = scrape_tags(summaries)
  
  title = scrape_titles(summaries)
  
  url = scrape_urls(summaries)
  
  views = scrape_views(summaries)
                     
  votes = scrape_votes(summaries)
  
  answers = scrape_replies(summaries)
  
  user = scrape_users(summaries)
  
  reputation = scrape_reputations(summaries)
  
  df = data.frame(id, date, tags, title, url, views, votes, answers, user, reputation)
  df$url = as.character(df$url)
  
  next_url = scrape_nexturl(html)
  
  list(next_url, df)
}


scrape_stack_overflow = function(tag, num_of_posts = NA, num_of_pages = NA){

  # check that user specified number of posts xor number of pages  
  if (!is.na(num_of_posts) & !is.na(num_of_pages)){
    return("Please specify only the number of posts OR the number of pages, not both!")
  }
  
  # construct url to correct tag
  # I assume that the tag is correctly spelled and exists
  # Further versions of this code could add error handling
  url = paste('http://stackoverflow.com/questions/tagged/', tag, sep = '')

  # if neither number of posts nor number of pages is specified, extract the total number of pages 
  if (is.na(num_of_posts) & is.na(num_of_pages)){
    num_of_pages = Inf
  }
  
  # else if number of posts is specified, convert that into number of pages
  # recall that the default number of posts per page on Stack Overflow is 15
  else if (is.na(num_of_pages)){
    num_of_pages = ceiling(num_of_posts / 15)  
  }
  
  # else if number of pages is specified, save as number of pages
  # technically unnecessary
  else {
    num_of_pages = num_of_pages
  }
  
  # scrape post data
  df = NULL
  i = 0
  while (i < num_of_pages){
  
    temp <- scrape_summaries(url)
    
    # append new page's data to data frame
    df = rbind(df, temp[[2]])
    
    # determine next url
    url = temp[[1]]
    
    # check that the next url exists
    if (is.null(url)){
      break;
    }
    
    i = i+1
  }

  if (is.na(num_of_posts)){
    return(df[1:(15*num_of_pages),])
  }
  else{
    return(df[1:num_of_posts,]) 
  }
}

scrape_questions = function(url){
  
  html = read_html(url)
  
  question = xml_find_all(html, "//div[@class = 'question']")
  
  qid = as.numeric(xml_text(xml_find_all(question, "@data-questionid")))
  
  path = ".//div[@class = 'user-details']/a"
  user = xml_text(xml_find_all(question, path))
  
  path = ".//div[@class = 'user-details']/a/@href"
  userid = xml_text(xml_find_all(question, path))
  userid = as.numeric(gsub("/.*", "", gsub("/users/", "", userid)))
  
  path = ".//div[@class = 'user-details']//span[@class = 'reputation-score']"
  reputation = xml_text(xml_find_all(question, path))
  reputation = as.numeric(gsub(",", "", reputation))
  
  path = ".//div[@class = 'user-action-time']/span/@title"
  date = as.POSIXct(xml_text(xml_find_all(question, path)))

  path = ".//div[@class = 'vote']//span[@class = 'vote-count-post ']"
  score = xml_text(xml_find_all(question, path))
  score = as.numeric(gsub(",", "", score))
  
  path = ".//div[@class = 'post-text']"
  text = as.character(xml_text(xml_find_all(question, path)))
  
  data.frame(url, user, userid, date, reputation, score, text, type = "question", parent = NA, id = qid, qid)
}

url = rownames(data)[1]

scrape_answers = function(url, question){
  
  html = read_html(url)
  
  answers = xml_find_all(html, "//td[@class = 'answercell']")
  
  if(length(answers) > 0){
    
    path = ".//div[@class = 'user-details']/a"
    user = xml_text(xml_find_all(answers, path))
    
    path = ".//div[@class = 'user-details']/a/@href"
    userid = xml_text(xml_find_all(answers, path))
    userid = as.numeric(gsub("/.*", "", gsub("/users/", "", userid)))
    
    path = ".//div[@class = 'user-action-time']/span/@title"
    date = as.POSIXct(xml_text(xml_find_all(answers, path)))
    
    path = ".//div[@class = 'user-details']//span[@class = 'reputation-score']"
    reputation = xml_text(xml_find_all(answers, path))
    reputation = as.numeric(gsub(",", "", reputation))
    
    path = "//div[@class = 'vote']//span[@class = 'vote-count-post ']"
    #remove first, because it will always be the question's score
    score = xml_text(xml_find_all(answers, path))[-1]
    score = as.numeric(gsub(",", "", score))
    
    text = as.character(xml_text(xml_find_all(answers, "./div[@class = 'post-text']")))
    
    path = ".//div[@class = 'post-menu']/a/@href"
    id = xml_text(xml_find_one(answers, path))
    id = as.numeric(gsub("/a/", "", id))
    
    return(data.frame(url, user, userid, date, reputation, score, 
                      text, type = "answer", parent = question$id, 
                      id, qid = question$id))
  } else {
    return(data.frame())
  }
}

scrape_comments = function(url, question){
  
  html = read_html(url)
  
  comments = xml_find_all(html, "//tr[@class = 'comment ']")
  
  if (length(comments) > 0){
    
    path = ".//div[@class = 'comment-body']/a[contains(@class, 'comment-user')]"
    user = xml_text(xml_find_all(comments, path))
    
    #userid
    path = ".//div[@class = 'comment-body']/a[contains(@class, 'comment-user')]/@href"
    userid = xml_text(xml_find_all(comments, path))
    userid = as.numeric(gsub("/.*", "", gsub("/users/", "", userid)))
    
    path = ".//span[@class = 'comment-date']/span/@title"
    date = as.POSIXct(xml_text(xml_find_all(comments, path)))
    
    path = ".//div[@class = 'comment-body']/a[contains(@class, 'comment-user')]/@title"
    reputation = xml_text(xml_find_all(comments, path))
    reputation = as.numeric(sub(" reputation", "", reputation))
    
    path = ".//td[@class = ' comment-score']"
    score = xml_text(xml_find_all(comments, path))
    score = as.numeric(gsub(",", "", gsub("\r\n *", "", score)))
    
    path = ".//td[@class = 'comment-text']//span[@class = 'comment-copy']"
    text = as.character(xml_text(xml_find_all(comments, path)))
    
    #Parent
    path = "//tr//tr[@class = 'comment ']"
    hits = xml_find_all(html, path)
    parent = unlist(lapply(hits, function(hit){
      path = xml_path(xml_parent(xml_parent(xml_parent(xml_parent(hit)))))
      parent = xml_attr(xml_find_one(html, paste(path, "/div[@class = 'comments ']", sep="")), "id")
      parent = as.numeric(gsub("comments-","",parent))
    }))
    
    id = xml_text(xml_find_all(comments, "./@id"))
    id = as.numeric(gsub("comment-", "", id))
    
    return(data.frame(url, user, userid, date, reputation, score, text, type = "comment", parent, id, qid = question$id))
  } else{
    data.frame()
  }
}

scrape_post = function(url){
  
  question = scrape_questions(url)
  
  answers = scrape_answers(url, question)
  
  comments = scrape_comments(url, question)
  
  rbind(question, answers, comments)
}

scrape_all_posts = function(urls){
  
  df2 = NULL
  for (i in 1:length(urls)){
    url = urls[i]
    temp = scrape_post(url)
    temp$text = as.character(temp$text)
    df2 = rbind(df2, temp)
  }
  return(df2)
}