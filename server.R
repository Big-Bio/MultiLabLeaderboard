rm(list=ls()) 

#setwd('/Users/robertbrown/Dropbox/SriramLab/leaderboard-googlesheets4/MultiLabLeaderboard_dev')
labname <- 'SriramLab'


library('googlesheets4')
library('googlesheets')
library('rcrossref')
library('dplyr')
library('ggplot2')
library('wordcloud')
library('tm')
library('anytime')
library('lubridate')
library('stringr')
library('reshape2')





secret_file_path <- './secretsDONOTSHARE/'
source(paste(secret_file_path,'url.R',sep=''))
source('configuration.R')

options(DT.options = list(pageLength = 100, rownames = FALSE))

theme_set(theme_bw(20))

shape_doi <- function(cpj) {
  res <- data.frame(
    url = NA,
    title = NA,
    authors = NA)
  if (!is.null(cpj)) {
    res$url <- paste0('https://doi.org/', cpj$DOI)
    res$title <- cpj$title
    res$authors <- paste0(paste0(cpj$author$given, ' ', cpj$author$family), collapse = ', ')
  }
  res
}

get_interactions = function(p) {
  users = sort(unique(p$handle))
  interactions = matrix(0, nrow = length(users), ncol = length(users),
    dimnames = list(users, users))

  p = dplyr::arrange(p, doi)

  current_doi = ''
  current_users = c()
  for (i in 1:nrow(p)) {
    if (p$doi[i] != current_doi) {
      # update the table
      all_combinations = NULL
      if (length(current_users) > 1) {
        all_combinations = combn(current_users, 2, simplify = FALSE)
      } else {
        who = current_users[1]
        interactions[who, who] = interactions[who, who] + 1
      }
      for (com in all_combinations) {
        interactions[com[1], com[2]] = interactions[com[1], com[2]] + 1
        interactions[com[2], com[1]] = interactions[com[2], com[1]] + 1
      }
      current_doi = p$doi[i]
      current_users = c()
    }
    current_users = c(current_users, p$handle[i])
  }
  interactions
}

# debugonce(get_interactions)
plot_network = function(papers, community = FALSE) {
  library('igraph')
  interactions = get_interactions(papers)
  total_papers = table(papers$handle)
  diag(interactions) = 0

  g = graph_from_adjacency_matrix(interactions, mode = 'undirected', weighted = TRUE)
  total_papers = total_papers[names(V(g))]

  w = E(g)$weight
  v = total_papers * 15 / median(total_papers)
  font_family = 'Helvetica'

  if (community) {
    community_object = cluster_optimal(g)
    plot(community_object, g, edge.width = w, vertex.size = v,
      vertex.label.family = font_family)
  } else {
    plot(g, edge.width = w, vertex.size = v,
      vertex.color = 'skyblue', vertex.label.family = font_family)
  }
}


update_doi_info <- function(doi) {
  
  doi_info <- sheets_read(prc4,sheet = 'read_only_doi')
  doi_info <- as.data.frame(doi_info)
  
  new_doi <- setdiff(doi, doi_info$doi)
  if (length(new_doi) > 0) {
    print(paste0('updating ', length(new_doi), ' record'))
    cr_result <- cr_cn(dois = new_doi, format = 'citeproc-json')
    # print(cr_result)
    if (length(cr_result) == 0)  {
      cr_result <- vector('list', length(new_doi))
      new_formatted_doi <- shape_doi(NULL)
    } else if (length(new_doi) == 1){
      # debugonce(shape_doi)
      new_formatted_doi <- shape_doi(cr_result)
      print(new_formatted_doi)
    } else {
      new_formatted_doi <- bind_rows(lapply(cr_result, shape_doi))
    }
    new_formatted_doi$doi <- new_doi
    if (length(new_doi) == 1 && !is.null(cr_result)) {
      new_formatted_doi$is_valid_doi <- TRUE
    } else if (length(new_doi) > 1){
      new_formatted_doi$is_valid_doi <- sapply(cr_result, function(x) !is.null(x))
    }
    doi_info$is_valid_doi=as.logical(doi_info$is_valid_doi)
    new_doi_info <- bind_rows(doi_info, new_formatted_doi)
    
    #gs_edit_cells(prc, ws = 'read_only_doi', input = new_doi_info)
    #sheets_deauth()
    sheets_write(data=new_doi_info,sheet = 'read_only_doi',ss=prc4)
    
    #sheets_create(prc4,sheets = list(read=papersinitial,read_only_doi=new_doi_info))
    
  }
  invisible(NULL)
}




# takes a DOI or DOI url and turns into DOI

sanitize_link4 <- function(doi4) {
  if (grepl('*doi*', doi4)) {
    doi4 <- sub('(http)*(s)*[[:punct:]]*doi(.org)?[[:punct:]]*', '', doi4)
    doi4 <- sub('<', '', doi4)
    doi4 <- sub('>', '', doi4)
  }
  doi4
}


# TODO: convert dates
# as.Date(as.POSIXct(1567790258, origin="1970-01-01"))
convert_date = function(d) {
  ret = rep(as.Date(NA), length(d))
  for (i in 1:length(d)) {
    ret[i] = anytime(as.integer(d[i]))
    if (is.na(ret[i])) {
      ret[i] = anytime(d[i])
    }
  }
  ret
}

aggregate_by_date = function(p, type) {
  p = group_by_(p, 'handle', type, 'year')
  p = summarize(p, n = length(doi))
  p = ungroup(p)
  p = group_by(p, handle)
  p = arrange_(p, 'handle', 'year', type)
  p = mutate(p, n_total = cumsum(n))
  p
}
# tmp = aggregate_by_date(papers, 'week')

mean_per_personweek = function(p, type) {
  p = group_by_(p, 'handle', type, 'year')
  p = summarize(p, n = length(doi))
  p = ungroup(p)
  p = group_by(p, handle)
  p = arrange_(p, 'handle', 'year', type)
  p = mutate(p, n_total = cumsum(n))
  p = ungroup(p)
  s=aggregate(p$n, by=list(Category=p$week), FUN=sum)
  s=mutate(s,mpppw=x/length(unique(p$handle)))
  colnames(s)=c('week','weekly_total','mean_per_personweek')
  s
}



count_by_date = function(p, type) {
  p = group_by_(p, 'handle', type, 'year')
  p = summarize(p, n = length(doi))
  p = ungroup(p)
  p = group_by(p, handle)
  p = arrange_(p, 'handle', 'year', type)
  p = mutate(p, n_total = cumsum(n))
  p = ungroup(p)
  s=aggregate(p$n, by=list(Category=p$week), FUN=sum)
  s=mutate(s,mpppw=x/length(unique(p$handle)))
  colnames(s)=c('week','weekly_total','mean_per_personweek')
  s
}




in_campaign = function(date, which_campaign) {
  stopifnot(nrow(which_campaign) == 1)
  which_campaign$start <= date & date <= which_campaign$stop
}


identify_campaigns = function(date) {
  out=sapply(date, function(x){campaigns$campaign[which(campaigns$start <= x & x <= campaigns$stop)]})
  out[which(lengths(out)==0)]='NoCampaign'
  unlist(out)
  }

read_comp_data = function(urls) {
    comp_data_all=data.frame()
    for (ii in c(1:nrow(urls))){
      ss=sheets_get(urls$compSheetID[ii])
      tempdata=data.frame(sheets_read(ss))
      #print(tempdata)
      comp_data_all=rbind(comp_data_all,tempdata)
    }
    comp_data_all
}







#sheets_auth(cache = ".secrets",email = "rpb2103@gmail.com")
options(gargle_oauth_cache = secret_file_path)

files <- list.files(secret_file_path)
token <- files[which(grepl('.com',files))]

sheets_auth(
  email = "rpb2103@gmail.com",
  path = NULL,
  scopes = "https://www.googleapis.com/auth/spreadsheets",
  cache = secret_file_path,
  token=token
)




prc_raw <- sheets_get(DB_URL)
raw_data <- sheets_read(prc_raw,sheet = 'raw_data')

df <- data.frame(doi=NA,handle=raw_data$handle, date=raw_data$date,recommend=NA,comments=NA)

for (i in c(1:nrow(df))){
  temp<-strsplit(raw_data$text[i],split = ' ')
  df$doi[i]<-temp[[1]][1]
  df$recommend[i]<-temp[[1]][2]
  df$comments[i]<-word(raw_data$text[i],start=3,end=sapply(strsplit(raw_data$text[i], " "), length), sep=' ')
}


prc4 <- sheets_get(DB_URL)
papers <- sheets_read(prc4,sheet = 'read')

papersNEW <- rbind(papers,df)
papersNEW <- papersNEW[!duplicated(papersNEW),]

sheets_write(data=papersNEW,sheet = 'read',ss=prc4)


papers <- sheets_read(prc4,sheet = 'read')



papers <- mutate(papers, doi = sapply(doi, sanitize_link4), date = convert_date(date))

papers <- mutate(papers, day = yday(date), week = week(date),
                 month = month(date), year = year(date))

papers$campaign <- identify_campaigns(papers$date)


#this counts the total papers read by the lab each week
count_week_year_camp <- melt(table(papers$week,papers$year,papers$campaign))
colnames(count_week_year_camp) <- c('week','year','campaign','total_papers')
count_week_year_camp$lab <- labname
count_week_year_camp

#this adds to the total count the total number of readers
temp=within(papers, { count <- ave(handle, campaign, FUN=function(x) length(unique(x)))})
temp=as.data.frame(unique(temp[,(c("campaign","count"))]))
colnames(temp)[2]='Nreaders'
count_week_year_camp=merge(count_week_year_camp,temp,by='campaign')

comp_data <- sheets_get(LC_URL)
sheets_write(count_week_year_camp,ss=comp_data,sheet = 'Sheet1')

#this reads all the competing lab metrix
compSheetIDtable <- read.table(paste(secret_file_path,'comp_sheetIDs.txt',sep=''),sep = ',',header = F)
compSheetIDtable$V1 <- as.character(compSheetIDtable$V1)
compSheetIDtable$V2 <- as.character(compSheetIDtable$V2)
colnames(compSheetIDtable) <- c('lab','compSheetID')

comp_data_all <- read_comp_data(compSheetIDtable)  
comp_data_all$total_papers <- as.numeric(comp_data_all$total_papers)
comp_data_all$Nreaders <- as.numeric(comp_data_all$Nreaders)
comp_data_all$lab=as.factor(comp_data_all$lab)
comp_data_all <- mutate(comp_data_all, mean_papers_per_personweek = total_papers/Nreaders)
comp_data_all <- subset(comp_data_all, mean_papers_per_personweek > 0)




  
cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2",
  "#D55E00", "#CC79A7")



user_count <- group_by(papers, handle)
user_count <- dplyr::filter(user_count, in_campaign(date, default_current_campaign))
user_count <- summarize(user_count, n = length(doi))
user_count


doi_count <- group_by(papers, doi)
doi_count <- summarize(doi_count, n = length(doi), who = paste(handle, collapse = ' '),
                       recommendation = paste(recommend, collapse = ' '))
doi_count <- arrange(doi_count, desc(n))
doi_count


#debugonce(update_doi_info)
update_doi_info(papers$doi)


doi_info <- sheets_read(prc4, 'read_only_doi')
doi_info <- left_join(doi_count, doi_info, by = c('doi'))


count_words = function(text) {
  # reference: http://www.sthda.com/english/wiki/print.php?id=159
  docs = VCorpus(VectorSource(text))
  # Convert the text to lower case
  docs <- tm_map(docs, content_transformer(tolower))
  # Remove numbers
  docs <- tm_map(docs, removeNumbers)
  # Remove stopwords for the language
  docs <- tm_map(docs, removeWords, stopwords('en'))

  excludeWords = c('paper', 'also', 'though')

  # Remove your own stopwords
  if(!is.null(excludeWords))
    docs <- tm_map(docs, removeWords, excludeWords)
  # Remove punctuations
  docs <- tm_map(docs, removePunctuation)
  # Eliminate extra white spaces
  docs <- tm_map(docs, stripWhitespace)

  tdm <- TermDocumentMatrix(docs)

  m <- as.matrix(tdm)
  v <- sort(rowSums(m),decreasing=TRUE)
  d <- data.frame(word = names(v),freq=v)
  d
}



shinyServer(function(input, output, session) {

  user_count <- reactive({
    user_count <- group_by(papers, handle)
    user_count <- dplyr::filter(user_count, in_campaign(date, current_campaign()))
    user_count <- summarize(user_count, n = length(doi))
    user_count
  })

  output$p_above_pritch <- renderText({
    df <- user_count()
    jp <- dplyr::filter(df, handle == 'sriram')
    lab <- dplyr::filter(df, handle != 'sriram')
    paste0(round(mean(lab$n > jp$n) * 100, 2), '%')
  })

  output$user_count_table <- renderDataTable({
    df <- arrange(user_count(), desc(n))
    df
  }, escape = FALSE,
  options = list(paging = FALSE))

  output$doi_count <- renderDataTable({
    datatable(doi_count)
  })

  output$p_user_count <- renderPlot({
    df = user_count()
    p <- ggplot(df, aes(reorder(handle, -n), n))
    p <- p + geom_bar(stat = 'identity')
    p <- p + xlab('user handle')
    p <- p + ylab('number of papers')
    p <- p + scale_y_continuous(breaks = seq(0, max(df$n), by = 5))
    p
  })

  output$doi_info <- DT::renderDataTable({
    res <- mutate(doi_info,
      url = ifelse(is_valid_doi, paste0('<a href="', url, '" target="_blank">', doi, '</a>'), doi))
    res <- select(res, -c(is_valid_doi, doi) )
    res
  }, escape = FALSE, rownames = FALSE,
      options = list(
        paging = FALSE,
        extensions = 'FixedColumns',
        scrollX = TRUE,
        scrollY = TRUE,
        fixedColumns = TRUE,
        autoWidth = FALSE,
        columnDefs = list(
          list(width = '5%', targets = c(0), visible = TRUE),
          list(width = '5%', targets = c(1), visible = TRUE),
          list(width = '10%', targets = c(2), visible = TRUE),
          list(width = '20%', targets = c(3), visible = TRUE),
          list(width = '30%', targets = c(4)),
          list(width = '30%', targets = c(5))
          )
        ))


  output$raw_data <- renderDataTable({
    res <- left_join(papers, doi_info, by = 'doi')
    datatable(res)
  })

  output$recommendation_cloud <- renderPlot({
    recommendation_count = count_words(papers$recommend)

    suppressWarnings(wordcloud(words = recommendation_count$word,
        freq = recommendation_count$freq,
      random.order = FALSE, rot.per = 0.35, colors = cbPalette)
      )
  })

  output$comment_cloud <- renderPlot({
    comments = count_words(papers$comments)

    suppressWarnings(
      wordcloud(words = comments$word, freq = comments$freq,
        random.order = FALSE, rot.per = 0.35, colors = cbPalette)
      )
  })

  output$network = renderPlot({
    plot_network(papers)
  })

  output$community = renderPlot({
    plot_network(papers, TRUE)
  })

  output$p_n_summary = renderPlot({
    current_papers  <-  dplyr::filter(papers, in_campaign(date, current_campaign()))
    df  <-  aggregate_by_date(current_papers, 'week')
    p  <-  ggplot(df, aes(week, n_total, color = handle))
    p  <-  p + geom_line()
    p  <-  p + geom_point()
    p
  })
  
  ## this is to make the graph of mean papers per week for the lab
  #current_comp_data_all = dplyr::filter(comp_data_all, campaign=='Winter 2020')
  
  output$mean_per_personweek_labcomp = renderPlot({
    current_comp_data_all  <-  dplyr::filter(comp_data_all, campaign==current_campaign()$campaign)
    current_comp_data_all <- current_comp_data_all[,c(2,5,7)]
    current_comp_data_all$week <- as.numeric(current_comp_data_all$week)
    current_comp_data_all$mean_papers_per_personweek <- as.numeric(current_comp_data_all$mean_papers_per_personweek)
    current_comp_data_all$lab <- as.character(current_comp_data_all$lab)
    p  <-  ggplot(current_comp_data_all, aes(week, mean_papers_per_personweek, color=lab))
    p  <-  p + geom_line()
    p = p + geom_point()
    p
  })
  
  output$lab_count_table <- renderDataTable({
    current_comp_data_all = dplyr::filter(comp_data_all, campaign==current_campaign()$campaign)
    #current_comp_data_all = dplyr::filter(comp_data_all, campaign==default_current_campaign$campaign)
    df=aggregate(current_comp_data_all$mean_papers_per_personweek, by=list(Category=current_comp_data_all$lab), FUN=sum)
    df$x=round(df$x, digits = 2)
    df <- arrange(df, desc(x))
    df
    colnames(df)[2]='mean_n_papers_pp'
    df
  }, escape = FALSE,
  options = list(paging = FALSE))
  
  


  current_campaign = reactive({
    dplyr::filter(campaigns, campaign == input$s_select_campaign)
  })

})

