# MultiLabLeaderboard
This is a paper reading tracker app for multiple labs to compare their average reading

The first version of this leaderboard was written by Harold Pimentel. He blogs about it here!

https://haroldpimentel.wordpress.com/2019/10/02/leaderboard/

and here is the original github repo he made

https://github.com/pimentel/leaderboard

Unfortunately the googlesheets API he used no longer works. So, here I have updated the API and added multi-lab competition capabilities. I have also removed the need to have a paid zapier account. So implementing this should be free.


This current version was made by me, Robert Brown, with help debugging and developing the README by Tommer Schwarz (@tommerschwarz).


Now, let's get to setting it up!



First step: 
1) Clone the repo to your computer
2) In the initial_setup.R script 
2a) for 'YOURemail' type your gmail that is associated with your google drive that you will be using
2b) for 'labname' create a one-word, no-space, no-special characters lab name (e.g. "SriramLab") in the initial_setup.R.   This lab name will also be used for lab competitions.
2c) for 'PIname' type the handle that your PI uses on slack (or the handle of whoever you are trying to beat as a lab)
change the working directory to be inside the repo, open the server.R file and set the working directory there as well to be inside the repo. 
2d)  update the working directory such that it points to inside of the file where the repo files are stored 


Second step: 
1) Open R and run the "initial_setup.R" script, do it line by line, if for some reason you may have to do it twice
-> this script will create a key for Google Sheets, DO NOT SHARE THIS KEY EVER
-> this script will also create two new google sheets in your google drive, these serve as databases
2) ***If you ran this multiple times, you will have multiple identically named google sheets in your drive, delete them all and do this again so that you only have one set of the two sheets it creates.

Third step: Set up Slack
1) In your lab's slack account, create a new channel called "paper_reading_hook"
2) Send the following message to the Slack channel you just created (you can delete this later from the database):

https://doi.org/10.1534/genetics.117.300489 yes a method for detecting polygenic adaptation.


Fourth step: Set up the Zapier. 
1) Get a Zapier account (zapier.com), a free account is fine
2) Click the "Make a Zap!" button
3) Find and select the Slack app
4) Choose Trigger should be set to "New Message Posted to Channel"
5) Follow the prompts to choose the appropriate slack account and channel ("paper_reading_hook")
6) set Trigger for Bot Messages to no
7) at the find data section, push "Test & Continue"
8) find and select the data entry that contains the message you posted to the slack channel
9) scroll down to the next be block that says "Do this ..." and click on it, Do NOT hit the plus button
10) Select Google Sheets
11) Select "Create a spreadsheet row"
12) Leave the Drive field empty, the default will be your Google Drive
13) For Spreadsheet, select DB-Leaderboard that was created with the "initial_setup.R"
14) For Worksheet, select "raw_data"
15) For "handle(optional)" look to the right side of the field, and there is a lines with plus symbol, 
    hit that and select the "User Name" line, it should have your username in it
16) For "Data(optional)", same idea as in 15, but selec the "Ts" field that has a big number in it
17) For "Text (optional)", same idea as in 15, select "Raw Text"
18) Up at the top, you can name the Zap anything you want, but I will call it "PaperReadingZap"
19) Turn on your Zap!!
20) Test it out, post new entries to the reading hook and see if they appear in the raw data sheet of the DB-leaderboard,
    entries are formatted <doi link> <one word recommendation> <comments> there must be a comment of some time, even if just a "."
  
  
 Fifth Step:
 1) Open the DB-leaderboard google sheet, go to the "raw_data" sheet. Delete the 2nd row that is full of "na"s. Nothing will work if you do not do this at this point. There must be an initializing entry (which you can delete later), but it needs to be a real entry, if you are entering things into slack, there should be entries here.
 
 
 Sixth Step:
 1) Open the server.R script. You should have already updated the working directory and the labname.
 2) In the top right there is a button that says "Run App" press it. Cross your fingers!
3) If it does not run, then... well, have fun debugging
4) Open the DB-leaderboard google sheet, and delete the rows that are full of "na"s in the "read" and "read_only_doi" tabs.


 
Seventh Step: lab competitions
 1) Right now you should have your lab name for lab competitions. If you don't want to setup lab competitions, you can move onto deploying your app now. You can also come back to this step in the future and set up competitions, if you do that, you will just need to redeploy the app once you add competing labs.
 2) Contact whoever at the lab you want to compete with is hosting the google sheets used for their instance of this reading leaderboard. Ask them to "read-only" share with you their "DB-leaderboard-metrics" google sheet. ****The must input into the share screen your email address that is associated with your google drive! So provide them with the correct email to invite you!
 3) You will be sent a link to their sheet, from the link, follow the link. Then, identify the sheet ID from the URL. (https://stackoverflow.com/questions/36061433/how-to-do-i-locate-a-google-spreadsheet-id)
 4) In the secretsDONOTSHARE folder that was made in the repo directory, open the file called "comp_SheetIDs.txt.  On a new line (don't leave blank lines, add a one-word, no-space, no-special characters lab name of your choosing for the lab that you will compete with, then put a comma, then put the sheet ID you found from the link they shared. Do not use any spaces when doing this. This file will be read as a CSV file. Save the file.
 5) Exit Rstudio, then start it again, go to the server.R file, then push Run App again. Hopefully it should work and will add a lab in the competition graphs!
 6) you will need to re-deploy the app to shinyapps (ignore this if you have not deployed yet).
 

Eighth Step: set up shinyapps
 1) follow the directions here to set up an account and link to to Rstudio https://shiny.rstudio.com/articles/shinyapps.html
 2) comment out the setwd() command in your server.R file
 3) deploy your app to shinyapps!
 
 Ninth Step: victory lap
 1) Go tell your PI how cool you are!
 2) In lab meeting propose a food based reward for achieving some reading metric! 
 3) Reach out to other labs to start competing!
 
 
