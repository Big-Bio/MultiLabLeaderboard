rm(list=ls()) 


labname <- 'SriramLab'
setwd('/Users/robertbrown/Dropbox/SriramLab/leaderboard-googlesheets4/MultiLabLeaderboard')



#devtools::install_github("tidyverse/googlesheets4")
secret_file_path <- './secretsDONOTSHARE/'

library('filesstrings')
library('googlesheets4')

# This will get a token to access your google sheets !!!!! DO NOT EVER SHARE OR POST OR PUSH THE TOKEN
sheets_auth(email = "rpb2103@gmail.com")
token=list.files('~/.R/gargle/gargle-oauth')
print('DO NOT EVER SHARE THE TOKEN YOU JUST CREATED, NEVER PUT IT ON GITHUB, EVEN PRIVATE, IT SHOULD BE SET TO SAVE TO A FILE OUTSIDE  OF THE REPO')


dir.create(secret_file_path)
list.files(secret_file_path)
list.files('~/.R/gargle/gargle-oauth/')
file.move(paste('~/.R/gargle/gargle-oauth/',token,sep=''), secret_file_path)
list.files(secret_file_path)

#Here I want to create all the google sheets I will need and then initialize them all correctly

sheets_has_token()


raw_data <- data.frame(handle='na', date='na', text='na')
read <- data.frame(doi='na', handle='na', date='na', recommend='na', comments='na')
read_only_doi <- data.frame(url='na',title='na',authors='na',doi='na',is_valid_doi='FALSE')

ss <- sheets_create( "DB-leaderboard", sheets = list(read=read, read_only_doi=read_only_doi, raw_data=raw_data))
temp <- sheets_get(ss)
dbURL <- temp$spreadsheet_url

#ppp <- data.frame(labname='na', week='na', papersperperson='na')
#pp <- sheets_create( "DB-leaderboard-ppp", sheets = list(ppp=ppp))
#temp <- sheets_get(pp)
#dbPPP_URL <- temp$spreadsheet_url

labcmp <- sheets_create("DB-leaderboard-metrics")
temp <- sheets_get(labcmp)
labcomp_URL <- temp$spreadsheet_url
labcomp_ID <- temp$spreadsheet_id

write(paste("DB_URL='",dbURL,"'",sep=''), file = paste(secret_file_path,'url.R',sep=''),append = F)
#write(paste("PPP_URL='",dbPPP_URL,"'",sep=''), file = paste(secret_file_path,'url.R',sep=''),append = T)
write(paste("LC_URL='",labcomp_URL,"'",sep=''), file = paste(secret_file_path,'url.R',sep=''),append = T)



## This creates a file for competition, the sriram lab is the default competition
SiramPUB <- '1jRjcvE7_tAc06lqL2WRdxUOraLMvv_rcmN_8boTGNPI'
tempPUB <- '1j74YHD8H-bfc6ldwhguhdRcZ3lbGR44ExJa-iFkEXA8'

write(paste(labname,labcomp_ID,sep=','), file = paste(secret_file_path,'comp_SheetIDs.txt',sep=''),append = F)


