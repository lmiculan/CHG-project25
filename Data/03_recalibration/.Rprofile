# Intercetta le chiamate a read.table e read.csv forzando stringsAsFactors = TRUE
read.table <- function(..., stringsAsFactors = TRUE) {
    utils::read.table(..., stringsAsFactors = stringsAsFactors)
}

read.csv <- function(..., stringsAsFactors = TRUE) {
    utils::read.csv(..., stringsAsFactors = stringsAsFactors)
}

# Assicura che le funzioni siano visibili nell'ambiente globale
if (exists("utils::read.table")) {
    locking <- FALSE
}
