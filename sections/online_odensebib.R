source("global.R")
source("modules.R")
source("~/.postpass")

# UI

online_odensebibTabPanelUI <- function(id) {
  
  ns <- NS(id)
  
    
    tabItem(tabName = "odensebib",
            
            box(width = 12, solidHeader = TRUE, id="onlineheader2",
                h3("Odensebib.dk"),
                img(src='online.png', align = "right", height="46px")
            ),
            
            fluidRow(
              column(12,
                     tabBox(width = 12,
                            id = "tabset1", height = "250px",
                            tabPanel("Generelt", 
                                     fluidRow(
                                       column(12,
                                              column(width = 4,
                                                     h4("Sidevisninger"), 
                                                     plotlyOutput(ns("plot1")),
                                                     tableOutput(ns("ga_pageviewstable"))
                                              ),
                                              column(width = 4,
                                                     h4("Enheder"),  
                                                     plotlyOutput(ns("ga_device_plot"))
                                              ),
                                              column(width = 4,
                                                     h4("Top 10 sider 2017"), 
                                                     formattableOutput(ns("tableplot3"))
                                              )
                                       )
                                     )   
                            ),
                            tabPanel("Indholdsgrupper", ""),
                            tabPanel("Kampagner", "")
                     )
              )
            )
    )
  
  # tabItem(tabName = "app",
  #         box(width = 12,
  #             h3("Biblioteket App")
  #         )
  # ),
  
}

# SERVER

online_odensebibTabPanel <- function(input, output, session) {

  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname, host = host, port = port, user = user, password = password)
  ga_pageviews <- dbGetQuery(con, "SELECT * FROM datamart.ga_pageviews where pageviews > 0")
  ga_device <- dbGetQuery(con, "select device, sum(users) as users from datamart.ga_device group by device")
  ga_top10 <- dbGetQuery(con, "SELECT title, pageviews FROM datamart.ga_top10 order by pageviews desc limit 11 offset 1")
  sites <- dbGetQuery(con, "SELECT * FROM datamart.sites")
  dbDisconnect(con)
  
  # sites
  
  sites <- sites %>% select("Organisation" = titel, "URL" = url)
  output$tablesites <- renderTable(sites)
  
  # pageviews
  
  ga_pageviews <- ga_pageviews %>%
    mutate(pv2018 = ifelse(aar == "2018", pageviews, 0), pv2017 = ifelse(aar == "2017", pageviews, 0), pv2016 = ifelse(aar == "2016", pageviews, 0), pv2015 = ifelse(aar == "2015", pageviews, 0)) %>%
    select(maaned,pv2015,pv2016,pv2017,pv2018) %>%
    group_by(maaned) %>%
    summarise(v2018 = sum(pv2018), v2017 = sum(pv2017), v2016 = sum(pv2016), v2015 = sum(pv2015))
  is.na(ga_pageviews) <- !ga_pageviews
  
  output$plot1 <- renderPlotly({
    plot_ly(ga_pageviews, x = ~maaned , y = ~v2015 , type = "bar", name = '2015', marker = list(color = color1)) %>%
      add_trace(y = ~v2016, name = '2016', marker = list(color = color2)) %>%
      add_trace(y = ~v2017, name = '2017', marker = list(color = color3)) %>%
      add_trace(y = ~v2018, name = '2018', marker = list(color = color4)) %>%
      layout(showlegend = T, xaxis = list(tickmode="linear", title = "Måned"), yaxis = list(title = "Antal"))  
  })
  
  # device
  
  output$ga_device_plot <- renderPlotly({
    plot_ly(ga_device, labels = ~device, values = ~users, marker = list(colors = colors, line = list(color = '#FFFFFF', width = 1))) %>%
      add_pie(hole = 0.6) %>%
      layout(showlegend = T,
             xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
             yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE))
  })
  
  # top10 pages 2017
  
  ga_top10 <- ga_top10 %>% 
    filter(title != "Adgang nægtet | Odense Bibliotekerne") %>%
    rename(Titel = title, Sidevisninger = pageviews )
  
  output$tableplot3 <- renderFormattable({formattable(ga_top10)})
  
  
  
}