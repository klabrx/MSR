library(shiny)
library(shinyjs)

# Lade das vorbereitende Skript, das alle nötigen Daten und Funktionen bereitstellt
source("./scripts/prepApp.r")

# UI
ui <- fluidPage(
  useShinyjs(),
  
  # Einbindung der externen CSS-Datei (Falls vorhanden)
  includeCSS("styles/styles.CSS"),
  
  # Fixierter Header
  div(id = "result-header", "Result-Header"),
  
  # Hauptinhalt
  div(id = "main-content",
      fluidRow(
        column(4, 
               h3("Eingabefelder"),
               # Eingabefeld für Wohnungsgröße, begrenzt an die Referenztabelle
               numericInput("wohn_groesse_input", "Wohnungsgröße in m²", 
                            value = NA, min = min(reference_table$von), 
                            max = max(reference_table$bis_unter), step = 0.1)
        ),
        column(8, 
               h3("Result-Report"),
               # Dynamischer Report, der mit renderUI generiert wird
               uiOutput("report_ui")
        )
      )
  ),
  
  # Fixierter Footer
  div(id = "result-footer", "Datenschutzerklärung | Impressum")
)

# Server
server <- function(input, output, session) {
  
  # Dynamischer Ergebnisbericht, der automatisch aktualisiert wird
  output$report_ui <- renderUI({
    
    # Prüfen, ob eine Wohnungsgröße angegeben wurde
    if (is.na(input$wohn_groesse_input)) {
      return(HTML("<table class='table'>
                  <tr><th>Merkmal</th><th>Angaben</th><th>Von</th><th class='highlight'>Ortsüblich</th><th>Bis</th></tr>
                  <tr><td>Wohnungsgröße</td><td>Pflichtangabe fehlt</td><td></td><td class='highlight'></td><td></td></tr>
                  </table>"))
      
    } else {
      # Wohnungsgröße aus dem Input
      wohn_groesse <- input$wohn_groesse_input
      
      # Finde den Bereich in der Referenztabelle
      row <- reference_table[reference_table$von <= wohn_groesse & reference_table$bis_unter > wohn_groesse, ]
      
      if (nrow(row) == 1) {
        return(HTML(paste0("<table class='table'>
                           <tr><th>Merkmal</th><th>Angaben</th><th>Von</th><th class='highlight'>Ortsüblich</th><th>Bis</th></tr>
                           <tr><td>Wohnungsgröße</td><td>von ", row$von, " bis unter ", row$bis_unter, " m²</td><td>", 
                           row$low, "</td><td class='highlight'>", row$med, "</td><td>", row$hi, "</td></tr>
                           </table>")))
      } else {
        return(HTML("<table class='table'>
                    <tr><th>Merkmal</th><th>Angaben</th><th>Von</th><th class='highlight'>Ortsüblich</th><th>Bis</th></tr>
                    <tr><td>Wohnungsgröße</td><td>Kein passender Bereich gefunden</td><td></td><td class='highlight'></td><td></td></tr>
                    </table>"))
      }
    }
  })
}

# Shiny App
shinyApp(ui = ui, server = server)
