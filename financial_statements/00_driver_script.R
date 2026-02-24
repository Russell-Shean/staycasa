

# load and clean data
for(file in list.files("financial_statements//02_clean_data", 
                       full.names = TRUE)){
  
  source(file, encoding = "UTF-8")
}


# create overall categories
source("financial_statements/03_merge_data.R")
source("financial_statements/04_create_spreadsheets.R")
