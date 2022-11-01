library(knitr)  
library(dplyr)

# https://bookdown.org/yihui/rmarkdown-cookbook/kable.html
print_table <- function(df) {
  kable(df, format = "simple", align = "r", sep.col = " ")
}

data.frame(
  occurrenceID = c("urn:ABC:occ:123", "urn:ABC:occ:124"),
  scientificName = c("Abra alba", "Lanice"),
  scientificNameID = c("urn:lsid:marinespecies.org:taxname:141433", "urn:lsid:marinespecies.org:taxname:129697"),
  eventDate = c("2022-10-03", "2022-10-03"),
  decimalLongitude = c("3.456", "3.456"),
  decimalLatitude = c("51.987", "51.987")
) |> print_table()

data.frame(
  eventID = c("urn:ABC:event:789"),
  eventDate = c("2022-10-03"),
  decimalLongitude = c("3.456"),
  decimalLatitude = c("51.987")
) |> print_table()

data.frame(
  eventID = c("urn:ABC:event:789", "urn:ABC:event:789"),
  occurrenceID = c("urn:ABC:occ:123", "urn:ABC:occ:124"),
  scientificName = c("Abra alba", "Lanice"),
  scientificNameID = c("urn:lsid:marinespecies.org:taxname:141433", "urn:lsid:marinespecies.org:taxname:129697")
) |> print_table()

data.frame(
  eventID = c("urn:ABC:event:42", "urn:ABC:event:789"),
  parentEventID = c("", "urn:ABC:event:42"),
  eventDate = c("", "2022-10-03"),
  decimalLongitude = c("3.456", ""),
  decimalLatitude = c("51.987", "")
) |> print_table()

data.frame(
  eventID = c("urn:ABC:event:789", "urn:ABC:event:789"),
  measurementType = c("temperature", "salinity"),
  measurementValue = c("17", "31"),
  measurementUnit = c("degrees C", "psu")
) |> print_table()

data.frame(
  scientificName = c("Abra alba", "Lanice"),
  scientificNameAuthorship = c("(W. Wood, 1802)", "Malmgren, 1866"),
  taxonRank = c("species", "genus"),
  scientificNameID = c("urn:lsid:marinespecies.org:taxname:141433", "urn:lsid:marinespecies.org:taxname:129697"),
  identificationQualifier = c("", "cf. conchilega")
) |> print_table()


data.frame(
  decimalLatitude = c(38.698, 42.72),
  decimalLongitude = c(20.95, 15.228),
  geodeticDatum = c("EPSG:4326", "EPSG:4326"),
  coordinateUncertaintyInMeters = c(75033, 154338),
  footprintWKT = c("LINESTRING (20.31 39.15, 21.58 38.24)", "LINESTRING (16.64 41.80, 13.82 43.64)")
) |> print_table()
