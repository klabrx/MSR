library(shiny)
library(shinyjs)

# UI
ui <- fluidPage(
  useShinyjs(),
  
  # Einbindung der externen CSS-Datei
  includeCSS("styles/styles.CSS"),
  
  # Fixierter Header
  div(id = "result-header", "Result-Header"),
  
  # Hauptinhalt
  div(id = "main-content",
      fluidRow(
        column(4, 
               h3("Eingabefelder"),
               # Platzhalter für Eingabefelder
               textInput("input1", "Eingabefeld 1", value = ""),
               textInput("input2", "Eingabefeld 2", value = ""),
               actionButton("submit", "Abschicken")
        ),
        column(8, 
               h3("Result-Report"),
               # Platzhalter für Ergebnisbericht
               verbatimTextOutput("report")
        )
      )
  ),
  
  # Fixierter Footer
  div(id = "result-footer", "Datenschutzerklärung | Impressum")
)

# Server
server <- function(input, output, session) {
  
  # Dynamischer Ergebnisbericht
  output$report <- renderText({
    paste("Ergebnis 1:", input$input1, "\n",
          "Ergebnis 2:", input$input2)
  })
}

# Shiny App
shinyApp(ui = ui, server = server)
