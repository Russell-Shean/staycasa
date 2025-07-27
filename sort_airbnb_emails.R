airbnb_replies <- airbnb_emails |> 
  filter(str_detect(subject, "RE:.*預訂"))


airbnb_cancelations <- airbnb_emails |> 
  filter(str_detect(subject, "已取消："))


cancelation_numbers <- airbnb_cancelations |>
                       pull(confirmation_number)
