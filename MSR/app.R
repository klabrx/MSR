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
               h3("Angaben zur Wohnung"),
               # Eingabefeld für Wohnungsgröße, begrenzt an die Referenztabelle
               numericInput("wohn_groesse_input", "Größe in m² lt. Mietvertrag", 
                            value = NA, min = min(reference_table$von), 
                            max = max(reference_table$bis_unter), step = 0.1),
               # Dropdown-Feld für die Adresseingabe, startet leer
               selectInput("adresse_input", "Adresse", 
                           choices = c("", adress_vorschlaege), 
                           selected = NULL, 
                           multiple = FALSE)
        ),
        column(8, 
               h3("Ergebnis"),
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
    
    # Platzhalter für Ergebnisse der Wohnungsgröße
    wohn_groesse_result <- "<p>Pflichtangabe fehlt (Wohnungsgröße)</p>"
    von_adjusted <- med_adjusted <- bis_adjusted <- "NA"
    von_faktor <- med_faktor <- bis_faktor <- "NA"
    sum_von <- sum_med <- sum_bis <- 0
    nettokaltmiete_von <- nettokaltmiete_med <- nettokaltmiete_bis <- "NA"
    
    # Wenn Wohnungsgröße angegeben ist, berechnen
    if (!is.na(input$wohn_groesse_input)) {
      row <- reference_table[reference_table$von <= input$wohn_groesse_input & reference_table$bis_unter > input$wohn_groesse_input, ]
      
      if (nrow(row) == 1) {
        wohn_groesse_result <- paste0("von ", row$von, " bis unter ", row$bis_unter, " m²")
        von_adjusted <- round(as.numeric(gsub(",", ".", gsub(" ", "", row$low))), 2)
        med_adjusted <- round(as.numeric(gsub(",", ".", gsub(" ", "", row$med))), 2)
        bis_adjusted <- round(as.numeric(gsub(",", ".", gsub(" ", "", row$hi))), 2)
        
        sum_von <- von_adjusted
        sum_med <- med_adjusted
        sum_bis <- bis_adjusted
      }
    }
    
    # Platzhalter für Ergebnisse der Lage
    lage_result <- "<p>Pflichtangabe fehlt (Adresse)</p>"
    
    # Wenn Adresse angegeben ist, berechnen
    adresse <- input$adresse_input
    if (!is.null(adresse) && adresse != "") {
      adresse_row <- sf_data[sf_data$STRASSE_HS == adresse, ]
      
      if (nrow(adresse_row) == 1) {
        wohnlage <- as.character(adresse_row$WL_2024)
        if (wohnlage %in% names(wohnlage_adjustments)) {
          lagenfaktor <- as.numeric(wohnlage_adjustments[[wohnlage]])
          lagenfaktor_text <- ifelse(lagenfaktor == 0, "±0", ifelse(lagenfaktor > 0, paste0("+", lagenfaktor * 100), paste0(lagenfaktor * 100)))
          lage_result <- paste0(adresse, " (WL: ", wohnlage, ", ", lagenfaktor_text, "%)")
          
          # Berechnung des Zu-/Abschlags durch Lagenfaktor
          von_faktor <- round(von_adjusted * lagenfaktor, 2)
          med_faktor <- round(med_adjusted * lagenfaktor, 2)
          bis_faktor <- round(bis_adjusted * lagenfaktor, 2)
          
          # Summierung der Faktoren zur Ortsüblichen Vergleichsmiete
          sum_von <- sum_von + von_faktor
          sum_med <- sum_med + med_faktor
          sum_bis <- sum_bis + bis_faktor
        }
      }
    }
    
    # Berechnung der Nettokaltmiete
    if (!is.na(input$wohn_groesse_input)) {
      nettokaltmiete_von <- round(sum_von * input$wohn_groesse_input, 2)
      nettokaltmiete_med <- round(sum_med * input$wohn_groesse_input, 2)
      nettokaltmiete_bis <- round(sum_bis * input$wohn_groesse_input, 2)
    }
    
    # Ergebnisse in der Tabelle anzeigen, inklusive Summenzeile und Nettokaltmiete-Zeile
    return(HTML(paste0("<table class='table'>
                         <tr><th>Merkmal</th><th>Angaben</th><th style='text-align: center;'>Von</th><th style='text-align: center;' class='highlight'>Ortsüblich</th><th style='text-align: center;'>Bis</th></tr>
                         <tr><td>Wohnungsgröße</td><td>", wohn_groesse_result, "</td><td style='text-align: center;'>", 
                       von_adjusted, "</td><td style='text-align: center;' class='highlight'>", med_adjusted, "</td><td style='text-align: center;'>", bis_adjusted, "</td></tr>
                         <tr><td>Lage</td><td>", lage_result, "</td><td style='text-align: center;'>", 
                       von_faktor, "</td><td style='text-align: center;' class='highlight'>", med_faktor, "</td><td style='text-align: center;'>", bis_faktor, "</td></tr>
                         <tr><td colspan='2'><b>Ortsübliche Vergleichsmiete:</b></td><td style='text-align: center;'><b>", 
                       sum_von, "</b></td><td style='text-align: center;' class='highlight'><b>", sum_med, "</b></td><td style='text-align: center;'><b>", sum_bis, "</b></td></tr>
                         <tr><td colspan='2'><b>Nettokaltmiete für die angegebenen ", input$wohn_groesse_input, " m²:</b></td><td style='text-align: center;'><b>", 
                       nettokaltmiete_von, "</b></td><td style='text-align: center;' class='highlight'><b>", nettokaltmiete_med, "</b></td><td style='text-align: center;'><b>", nettokaltmiete_bis, "</b></td></tr>
                         </table>")))
  })
}

# Shiny App
shinyApp(ui = ui, server = server)
