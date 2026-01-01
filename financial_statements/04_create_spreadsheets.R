library(openxlsx)
library(dplyr)


# Create workbook
wb <- createWorkbook()

# default font style
# Create a base Arial style
default_style <- createStyle(fontName = "Arial",
                             halign = "left"
)


# determine column widths

col_widths <- c()

for(col in colnames(combined_transactions)){
  
  max_width <- combined_transactions |> pull(col) |> as.character() |> nchar() |> max(na.rm=TRUE)
  
  if(max_width < nchar(col)){
    
    max_width <- nchar(col)
  }
  
  # Add some cushion
  max_width <- max_width + 5
  
  col_widths <- c(col_widths, max_width)
  
  
}

print(col_widths)



# add financial report 2 as the first sheet
# add sheet
addWorksheet(wb, "Summary")


# Apply Arial font to the entire table (header + data)
addStyle(
  wb,
  sheet = "Summary",
  style = default_style,
  rows = 1:(nrow(financial_report_format2) + 1),   # header row + data rows
  cols = 1:ncol(financial_report_format2),
  gridExpand = TRUE
)

# Make first row bold
addStyle(
  wb,
  sheet = "Summary",
  style = createStyle(textDecoration = "bold"),
  rows = 1,
  cols = 1:ncol(financial_report_format2),
  gridExpand = TRUE
)

# Write dataframe starting at row 1, col 1
writeData(wb, "Summary", financial_report_format2, startRow = 1, startCol = 1)


# adjust column widths
setColWidths(wb, "Summary" , cols = 1, widths = 30)
setColWidths(wb, "Summary" , cols = 2:ncol(financial_report_format2), widths = 12)


categories <- c("Revenue", "Rent", "Cleaning", "Water and Electricity", 
                "Internet and TV", "Other - COGS", "Other - Operating Expenses", 
                
                "Capital Injection", "Dividend Distribution", "Deposit")


for(catg in categories){
  
  # add sheet
  addWorksheet(wb, catg)
  
  # filter data
  df <- combined_transactions |>
    filter(category2 == catg) |> 
    arrange(transaction_date)
  
  
  # Apply Arial font to the entire table (header + data)
  addStyle(
    wb,
    sheet = catg,
    style = default_style,
    rows = 1:(nrow(df) + 1),   # header row + data rows
    cols = 1:ncol(df),
    gridExpand = TRUE
  )
  
  
  # Write dataframe starting at row 1, col 1
  writeData(wb, catg, df, startRow = 1, startCol = 1)
  
  
  # set colwidths
  for(i in seq_along(col_widths)){
    
    setColWidths(wb, catg, cols = i, widths = col_widths[i])
  }
  
  
  # Make first row bold
  addStyle(
    wb,
    sheet = catg,
    style = createStyle(textDecoration = "bold"),
    rows = 1,
    cols = 1:ncol(df),
    gridExpand = TRUE
  )
  
  
}


# Save workbook
saveWorkbook(wb, "data/transactions_by_category.xlsx", overwrite = TRUE)
  
