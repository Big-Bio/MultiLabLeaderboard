campaigns = list(
  data.frame(campaign = 'Winter 2020', start = '2020-01-01', stop = '2020-03-24',
             stringsAsFactors = FALSE),
  data.frame(campaign = 'Spring 2020', start = '2020-03-25', stop = '2020-06-12',
             stringsAsFactors = FALSE),
  data.frame(campaign = 'Summer 2020', start = '2020-06-13', stop = '2020-09-11',
             stringsAsFactors = FALSE),
  data.frame(campaign = 'Fall 2020', start = '2020-09-12', stop = '2021-01-01',
             stringsAsFactors = FALSE)
  )
campaigns = dplyr::bind_rows(campaigns)
campaigns = dplyr::mutate(campaigns, start = as.Date(start), stop = as.Date(stop))

default_current_campaign = dplyr::filter(campaigns, campaign == 'Winter 2020')
