rm(list=ls()) 

YOURemail='XXXXXXX@gmail.com'  #must be the email associated with hour google drive
labname <- 'XXXXXLab'
PIname='XXXXXXX'  #this is the handle of the PI on slack
setwd('XXXXXXXX')



#devtools::install_github("tidyverse/googlesheets4")
secret_file_path <- './secretsDONOTSHARE/'

library('filesstrings')
library('googlesheets4')

# This will get a token to access your google sheets !!!!! DO NOT EVER SHARE OR POST OR PUSH THE TOKEN
sheets_auth(email = YOURemail)
token=list.files('~/.R/gargle/gargle-oauth')
print('DO NOT EVER SHARE THE TOKEN YOU JUST CREATED, NEVER PUT IT ON GITHUB, EVEN PRIVATE, IT SHOULD BE SET TO SAVE TO A FILE OUTSIDE  OF THE REPO')


dir.create(secret_file_path)
list.files(secret_file_path)
list.files('~/.R/gargle/gargle-oauth/')
file.move(paste('~/.R/gargle/gargle-oauth/',token,sep=''), secret_file_path)
list.files(secret_file_path)


sheets_has_token()


raw_data <- data.frame(handle='na', date='na', text='na')
read <- data.frame(doi='na', handle='na', date='na', recommend='na', comments='na')
read_only_doi <- data.frame(url='na',title='na',authors='na',doi='na',is_valid_doi='FALSE')

ss <- sheets_create( "DB-leaderboard", sheets = list(read=read, read_only_doi=read_only_doi, raw_data=raw_data))
temp <- sheets_get(ss)
dbURL <- temp$spreadsheet_url


labcmp <- sheets_create("DB-leaderboard-metrics")
temp <- sheets_get(labcmp)
labcomp_URL <- temp$spreadsheet_url
labcomp_ID <- temp$spreadsheet_id

write(paste("DB_URL='",dbURL,"'",sep=''), file = paste(secret_file_path,'url.R',sep=''),append = F)
write(paste("LC_URL='",labcomp_URL,"'",sep=''), file = paste(secret_file_path,'url.R',sep=''),append = T)
write(paste("YOURemail='",YOURemail,"'",sep=''), file = paste(secret_file_path,'url.R',sep=''),append = T)
write(paste("PIname='",PIname,"'",sep=''), file = paste(secret_file_path,'url.R',sep=''),append = T)


write(paste(labname,labcomp_ID,sep=','), file = paste(secret_file_path,'comp_sheetIDs.txt',sep=''),append = F)


