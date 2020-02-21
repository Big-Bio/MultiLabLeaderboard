library('shiny')
library('DT')

source('configuration.R')

shinyUI(
  fluidPage(
    titlePanel('leaderboard'),
    fluidRow(
      tabsetPanel(
        tabPanel('leaderboard',
          fluidPage(
            plotOutput('p_user_count'),
            fluidRow(
              column(width = 4,
                p(paste('percentage of lab beating ',PIname,': '), textOutput('p_above_pritch'))),
              column(width = 4),
              column(width = 8, selectInput('s_select_campaign', 'Which campaign:',
                  campaigns$campaign, selected = default_current_campaign$campaign))
              ),
            fluidRow(
              column(width = 4,
               DT::dataTableOutput("user_count_table")
               ),
             column(width = 8,
               plotOutput('p_n_summary')
               )
              ),
            fluidRow(
              column(width = 8, plotOutput('mean_per_personweek_labcomp'))
            ),
            column(width = 4,
                   DT::dataTableOutput("lab_count_table")
            )
            )
          ),
        tabPanel('DOI info',
          fluidPage(
            fluidRow(
              column(
                width = 12,
                DT::dataTableOutput("doi_info")
                )
              )
            )
          ),
        tabPanel('raw data',
          {
            dataTableOutput('raw_data')
          })
        # end tabsetPanel
        )
      )
    )
  )
