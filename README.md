
# HPZoneAPI

<!-- badges: start -->
<!-- badges: end -->

R-package om het aanroepen van de HPZone API makkelijker te maken. Er zijn enkele functies om de syntax van GraphQL wat te versimpelen, automatische naamcorrecties uit te voeren, en de benodigde scope te detecteren. 

## Algemene tips

De *HPZone_request_xxx()* functies zijn ontworpen om zo makkelijk mogelijk te zijn in het dagelijks gebruik. Daarom zijn elementen die altijd uitgevoerd moeten worden hier standaard in verwerkt, en wordt er automatische tekencorrectie toegepast. Dit betekent dat het uitvoeren van de query korter kan dan in de handleiding aangegeven. De volgende query, zoals aangegeven in de handleiding, kan daardoor korter:

``` r
{"query": "{ cases (skip: 10, take: 50, order: [ { Case_creation_date: ASC } ], where: { Status: { eq: \"Open\" } }) { items { Case_identifier }, totalCount } }" }
```

Deze kan met *HPZone_request()* verkort en versimpeld worden uitgevoerd:
``` r
HPZone_request('cases (skip: 10, take: 50, order: [ { Case_creation_date: ASC } ], where: { Status: { eq: "Open" } }) { items { Case_identifier }, totalCount }')
```
Let hierbij vooral op het gebruik van de enkele quotes (') om de string te omvatten en het gebrek aan backslashes (\\) in de where-clausule. Deze worden binnen de functie automatisch toegevoegd.

## Installatie

Je kunt de huidige versie van HPZoneAPI installeren vanaf [GitHub](https://github.com/) met de volgende code:

``` r
# install.packages("devtools")
devtools::install_github("ggdatascience/HPZoneAPI")
```

## Voorbeelden

### Casuistiek opvragen
Een simpel voorbeeld is het ophalen van de 50 meest recente casussen:

``` r
library(HPZoneAPI)

HPZone_setup("client_id van je GGD", "client_secret van je GGD")
HPZone_request("cases(take: 50, order: [{ Case_creation_date: DESC }]) { items { Case_identifier }, totalCount }")
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
