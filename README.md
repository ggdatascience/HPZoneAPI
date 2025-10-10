
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

## Beveiliging

De API key vereist een client ID en client secret voor gebruik. Om deze niet in je script te hoeven zetten wordt de keyring package gebruikt om de informatie op te slaan in de keyring van je OS. Dit betekent dat je per computer éénmalig de benodigde informatie moet invoeren, waarna deze beveiligd wordt opgeslagen. Hierbij wordt gebruik gemaakt van extra versleuteling, zodat andere processen, die in theorie ook bij deze keyring zouden kunnen, geen toegang hebben tot de data. Instellen gaat door het aanroepen van de functie *HPZone_store_credentials()*, welke interactief zal vragen om de benodigde informatie. Hierna kan *HPZone_setup()* zonder argumenten worden uitgevoerd.

Eenmalig:
``` r
HPZone_store_credentials()
```

Later gebruik in een script:
``` r
HPZone_request("iets")
```

## Gebruik

De package kan globaal gezien op twee manieren gebruikt worden: 1) als simpele wrapper om de aanroep van de API te vergemakkelijken, of 2) als uitbreiding op de workflow om gebruik in code te verkorten. De ontwikkeling is vooral gericht op scenario 2, waarbij een onderzoeker vanuit R makkelijk queries wil kunnen uitvoeren. Alle elementen die volgen uit technische specificaties van de API worden hiermee zoveel mogelijk uit handen genomen. Denk hierbij bijvoorbeeld aan een maximaal aantal rijen per aanvraag, het gebruik van quotes in een query, het opzetten van selectiecriteria, en het omgaan met datatypes. Hierdoor kan de volgende code bijvoorbeeld flink worden ingekort.

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
data = HPZone_request("cases", "id", where=c("Status", "=", "Open"), order="Case_creation_date") %>%
  HPZone_convert_dates()
```
Of, als je toch liever handmatig de query schrijft:
``` r
data = HPZone_request_paginated('cases (order: [ { Case_creation_date: ASC } ], where: { Status: { eq: "Open" } }) { items { Case_identifier } }') %>%
  HPZone_convert_dates()
```

De *HPZone_request_xxx()* functies zijn ontworpen om zo makkelijk mogelijk te zijn in het dagelijks gebruik. Daarom zijn elementen die altijd uitgevoerd moeten worden hier standaard in verwerkt, en wordt er automatische tekencorrectie toegepast. Dit betekent dat het uitvoeren van de query korter kan dan in de handleiding aangegeven. Let hierbij vooral op het gebruik van de enkele quotes (') om de string te omvatten en het gebrek aan backslashes (\\) in de where-clausule. Deze worden binnen de functie automatisch toegevoegd. Verder is *sprintf()* geïntegreerd, en kun je dus gemakkelijk elementen dynamisch toevoegen.

## Query builder
Omdat GraphQL vol zit met eigenaardigheden, en dit zeker vanuit R voor onleesbare code kan zorgen, is er een speciale functie gemaakt die ook het ontwerpen van queries uit handen neemt. Hierbij hoef je niet meer na te denken over specifieke verschillen, zoals comparators (bijv. eq: vs. ==), hoef je niet meer te letten op specifieke spelling van velden ("case_creation" werkt net zo goed als "Case_creation_date"), en hoef je niet zelf de ingewikkelde logicastructuur toe te passen. Deze functie werkt als volgt:

`HPZone_request(endpoint, fields, where=NA, order=NA, verbose=F)`

Hierbij zijn er in vrijwel ieder argument extra trucjes verstopt. Je hoeft bijvoorbeeld niet zelf alle velden mee te geven, maar kunt ook volstaan met keywords.

### Endpoint
De naam hoeft niet correct te zijn; alle vormen die lijken op de juiste spelling worden automatisch omgezet.

### Fields
Kan een lijst met velden zijn, of één van de volgende keywords:

- "all" - alle beschikbare velden binnen het gewenste endpoint
- "basic" - een subset van velden die meestal gebruikt worden voor surveillance
- "standard" - alle velden die binnen de scope standard vallen
- "id"/"none" - alleen datum en HPZone ID (let op: het HPZone ID is anders dan de unique identifier!)

Bij zowel "basic" als "standard" is het tevens mogelijk om de lijst uit te breiden:
```r
HPZone_request("cases", c("basic", "Latitude", "Longitude"))
```

Handige tip: de beschikbare velden zijn tevens aanwezig in de variabele *HPZone_fields*.

### Where
Een lijst met de gewenste and/or-structuur, een vector met velden en hun waarden, of simpelweg een string met de gewenste query.
De lijst kan als volgt worden opgemaakt:
```r
HPZone_request("cases", "all", where=list("and"=list(c("Case_creation_date", "gte", "2025-01-01"), list("or"=c("Infection", "=", "Leptospirosis", "Infection", "==", "Malaria")))))
```
Hierbij worden alle gevallen opgehaald die aangemaakt zijn op of na 2025-01-01 en de infectie "Leptospirosis" of "Malaria" hebben. Dit voorbeeld laat tevens zien dat alle vormen van comparators worden geaccepteerd; eq (GraphQL), = (SQL), of == (R).
Als er geen AND of OR nodig is kan dit geheel worden overgeslagen en volstaat een vector met 3 argumenten:
```r
HPZone_request("cases", "all", where=c("Case_creation_date", "gte", "2025-01-01"))
```

Een serie van argumenten zonder logica wordt omgezet naar ANDs. Als je bijvoorbeeld alles in 2025 wil hebben kun je dit doen:
```r
HPZone_request("cases", "all", where=c("Case_creation_date", "gte", "2025-01-01", "Case_creation_date", "<", "2026-01-01"))
```
Wat identiek is aan dit:
```r
HPZone_request("cases", "all", where=list("and"=c("Case_creation_date", "gte", "2025-01-01", "Case_creation_date", "<", "2026-01-01")))
```


### Order
De gewenste sortering, in het format veldnaam=volgorde. Volgorde is niet verplicht, en wordt indien missend aangenomen als "ASC".
```r
# Let op het fout gespelde veld: Case_creation_date vs. creation_date
HPZone_request("cases", "all", where=c("creation_date", ">", "2025-09-01"), order=c("Infection", "Case_creation_date"="desc"))
```
Zoals deze code laat zien is ook correcte spelling van de volgorde niet nodig; desc wordt net zo goed geaccepteerd als DESC.

## Voorbeelden

### Casuistiek opvragen
Een simpel voorbeeld is het ophalen van de 50 meest recente casussen:

``` r
library(HPZoneAPI)

# let op: HPZone_setup() kan ook worden overgeslagen, als HPZone_store_credentials() eerder is uitgevoerd
HPZone_setup("client_id van je GGD", "client_secret van je GGD")
HPZone_request_query("cases(take: 50, order: [{ Case_creation_date: DESC }]) { items { Case_identifier }, totalCount }")
```

### Een volledig jaar ophalen
``` r
library(HPZoneAPI)

# let op: HPZone_setup() kan ook worden overgeslagen, als HPZone_store_credentials() eerder is uitgevoerd
HPZone_setup("client_id van je GGD", "client_secret van je GGD")
cur_year = 2025
fields = c("ABR", "Date_of_onset", "Infection")
HPZone_request("cases", fields, where=c("creation_date", ">=", paste0(cur_year, "-01-01"), "creation_date", "<", paste0(cur_year+1, "-01-01"))) %>%
  HPZone_convert_dates()
# of gelijkwaardig:
HPZone_request_paginated('cases(where: { and: [ { Case_creation_date: { gte: "%d-01-01" } }, { Case_creation_date: { lt: "%d-01-01" } } ]  }) { items { %s } }'), cur_year, cur_year+1, str_c(fields, collapse=", ")) %>%
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

- HPZone_request() - automatische query builder, welke eveneens automatisch de resultaten pagineert
- HPZone_request_query() - 'convenience wrapper', welke de query verkort en automatisch de data uit de respons haalt (maximaal 500 rijen)
- HPZone_request_paginated() - verdere verwerking van HPZone_request_query(), waarbij automatisch de volledige respons wordt opgehaald (geen maximum)
- HPZone_request_raw() - basisfunctie voor het opvragen van data, zonder verdere correctie of verwerking (maximaal 500 rijen)
- HPZone_convert_dates() - voegt een kolom toe (standaard Date_stat) die gebruikt kan worden als 'date for statistics' en wijzigt automatisch kolommen met een datum in het juiste datatype in R (let op: standaard alleen kolommen met date/datum/Received_on in de naam, maar dit gedrag is aan te passen, zie de documentatie bij ?HPZone_convert_dates)
- HPZone_make_valid() - accepteert een lijst met verkeerd gespelde namen en zet deze om naar de correcte notatie
- HPZone_necessary_scope() - accepteert een lijst met veldnamen en retourneert de benodigde scope
- test_HPZone_token() - controleert of de ingevoerde API key correct is
- HPZone_setup() - initialisatiefunctie die altijd als eerste moet worden uitgevoerd, tenzij er credentials zijn opgeslagen
- HPZone_store_credentials() - slaat de API credentials op een veilige manier op voor makkelijker hergebruik
