source("FSA_CMA_Intersects.R")
CMA_ids <- read_csv(
  "CMA_IDs.csv",
  col_types = "ccccccc"
)
library(shiny)

ui <- fluidPage(

  titlePanel("Canadian Median Household Income"),
  sidebarLayout(
    sidebarPanel(
      selectInput(
        "CMA_from_dropdown",
        "Census Metropolitan Area:",
        CMA_ids$CMANAME
      ),
      downloadButton("downloadData", "Download FSA-level Data"),
      h2("Definitions and Notes"),
      h3("Census Metropolitan Area (CMA)"),
      p("Urban areas and the related surrounding regions as defined by Statistics Canada."),
      h3("Forward Sorting Area (FSA)"),
      p("Regions used for mail sorting by Canada Post. These correspond to the first three digits of a building's postal code."),
      h3("Notes:"),
      p("All data is from the Statistics Canada 2021 Census. 'Median income' refers to median after-tax household income. Red outline shows the CMA boundaries. Regions with missing data are marked grey. Regions in white are areas where the majority (90% or greater) of the area for a given FSA is outside the corresponding CMA.")
    ),
    mainPanel(
      h2("Median Household Income by Forward Sorting Area"),
      plotOutput("CMAPlot", width = "100%", height = "700px")
    )
  )
)


server <- function(input, output) {
  output$CMAPlot <- renderPlot({
    CMA_data <- intersect_FSAs_join_data(
      chosen_CMA = input$CMA_from_dropdown
    )
    FSA_CMA_plot(CMA_data)
  })
  output$downloadData <- downloadHandler(
    filename = function(){
      paste("FSA-incomes-", input$CMA_from_dropdown, ".csv", sep = "")
    },
    content = function(file){
      write.csv(
        intersect_FSAs_join_data(input$CMA_from_dropdown) %>% 
          FSA_CMA_df(),
        file,
        na = "",
        row.names = FALSE
      )
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)
