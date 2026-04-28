# cancelations

get_cancellation_numbers <- function(airbnb_emails) {
  
  cancelation_numbers <-  airbnb_emails |>
    filter(str_detect(subject, "已取消：")) |>
    mutate(confirmation_number = str_squish(str_extract(subject, "(?<=已取消：預訂).*(?=（)")),
           #guest_first_name = str_extract(body, "(?<=你的房客).*(?=必須取消)")
           ) |> 
    
    pull(confirmation_number) |>
    unique()
  

  cancelation_numbers
}
