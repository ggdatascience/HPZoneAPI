
# HPZoneAPI

<!-- badges: start -->
<!-- badges: end -->

R-package om het aanroepen van de HPZone API makkelijker te maken. Er zijn enkele functies om de syntax van GraphQL wat te versimpelen, automatische naamcorrecties uit te voeren, en de benodigde scope te detecteren. 

## Installatie

Je kunt de huidige versie van HPZoneAPI installeren vanaf [GitHub](https://github.com/) met de volgende code:

``` r
# install.packages("devtools")
devtools::install_github("ggdatascience/HPZoneAPI")
```

## Gebruik

De package kan globaal gezien op twee manieren gebruikt worden: 1) als simpele wrapper om de aanroep van de API te vergemakkelijken, of 2) als uitbreiding op de workflow om gebruik in code te verkorten. De ontwikkeling is vooral gericht op scenario 2, waarbij een onderzoeker vanuit R makkelijk queries wil kunnen uitvoeren. Alle elementen die volgen uit technische specificaties van de API worden hiermee zoveel mogelijk uit handen genomen. Denk hierbij bijvoorbeeld aan een maximaal aantal rijen per aanvraag, het gebruik van quotes in een query, en het omgaan met datatypes. Hierdoor kan de volgende code bijvoorbeeld flink worden ingekort.

Handmatig:
``` r
i = 0
total = 500
while (i < total) {
  data = HPZone_request_raw(paste0('{"query": "{ cases (skip: ', i, ', take: 500, order: [ { Case_creation_date: ASC } ], where: { Status: { eq: \\"Open\\" } }) { items { Case_identifier, Date_of_onset }, totalCount } }" }'))
  data$data$cases$items$Date_of_onset = as.Date(data$data$cases$items$Date_of_onset)
  total = data$data$cases$totalCount
}
```

Met gebruik van de package:
``` r
data = HPZone_request_paginated('cases (order: [ { Case_creation_date: ASC } ], where: { Status: { eq: "Open" } }) { items { Case_identifier } }') %>%
  HPZone_convert_dates()
```

De *HPZone_request_xxx()* functies zijn ontworpen om zo makkelijk mogelijk te zijn in het dagelijks gebruik. Daarom zijn elementen die altijd uitgevoerd moeten worden hier standaard in verwerkt, en wordt er automatische tekencorrectie toegepast. Dit betekent dat het uitvoeren van de query korter kan dan in de handleiding aangegeven. Let hierbij vooral op het gebruik van de enkele quotes (') om de string te omvatten en het gebrek aan backslashes (\\) in de where-clausule. Deze worden binnen de functie automatisch toegevoegd. 

## Voorbeelden

### Casuistiek opvragen
Een simpel voorbeeld is het ophalen van de 50 meest recente casussen:

``` r
library(HPZoneAPI)

HPZone_setup("client_id van je GGD", "client_secret van je GGD")
HPZone_request("cases(take: 50, order: [{ Case_creation_date: DESC }]) { items { Case_identifier }, totalCount }")
```

### Een volledig jaar ophalen
``` r
library(HPZoneAPI)

HPZone_setup("client_id van je GGD", "client_secret van je GGD")
cur_year = 2025
fields = "ABR, Date_of_onset, Infection"
HPZone_request_paginated(paste0('cases(where: { and: [ { Case_creation_date: { gte: "', cur_year, '-01-01" } }, { Case_creation_date: { lte: "', cur_year, '-12-31" } } ]  }) { items { ', fields, ' } }')) %>%
      HPZone_convert_dates()
```

### Namen corrigeren
``` r
library(HPZoneAPI)

HPZone_make_valid(fields="date of onset")
# verwachte uitvoer: Date_of_onset
```

### Benodigde scope opvragen
``` r
library(HPZoneAPI)

HPZone_necessary_scope(c("Diagnosis", "Case_number", "Entered_by"))
# verwachte uitvoer: standard
```

## Beschikbare functies

- HPZone_request() - 'convenience wrapper', welke de query verkort en automatisch de data uit de respons haalt (maximaal 500 rijen)
- HPZone_request_paginated() - verdere verwerking van HPZone_request(), waarbij automatisch de volledige respons wordt opgehaald (geen maximum)
- HPZone_request_raw() - basisfunctie voor het opvragen van data, zonder verdere correctie of verwerking (maximaal 500 rijen)
- HPZone_convert_dates() - wijzigt automatisch kolommen met een datum in het juiste datatype in R (let op: standaard alleen kolommen met date/datum in de naam, maar dit gedrag is aan te passen, zie de documentatie bij ?HPZone_convert_dates)
- HPZone_make_valid() - accepteert een lijst met verkeerd gespelde namen en zet deze om naar de correcte notatie
- HPZone_necessary_scope() - accepteert een lijst met veldnamen en retourneert de benodigde scope
- test_HPZone_token() - controleert of de ingevoerde API key correct is
- HPZone_setup() - initialisatiefunctie die altijd als eerste moet worden uitgevoerd
