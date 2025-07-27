airbnb_replies <- airbnb_emails |> 
  filter(str_detect(subject, "RE:.*預訂"))


airbnb_cancelations <- airbnb_emails |> 
  filter(str_detect(subject, "已取消："))

airbnb_reminders <- airbnb_emails |> 
      filter(str_detect(subject, "提醒：.*快要入住了"))
