# ./script/prepApp.R

# Laden der Referenztabelle
reference_table <- read.csv("./data/RefTab_Groesse.csv", sep = ";", stringsAsFactors = FALSE)

# Laden der Datei und Extrahieren des DataFrames sf_data
load("./data/adr_2024.RData")

# Erstellen einer Liste von Adressvorschlägen für das Suchfeld
adress_vorschlaege <- unique(sf_data$STRASSE_HS)

# Definieren der Lagenfaktoren
wohnlage_adjustments <- list(
  "A" = 0.00,  # No adjustment
  "B" = -0.07, # 7% decrease
  "C" = -0.10  # 10% decrease
)

