

# load and clean data
for(file in list.files("financial_statements//02-clean_data", 
                       full.names = TRUE)){
  
  source(file)
}
