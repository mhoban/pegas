## geo.R (2020-03-05)

##   Tools for Geographic Data

## Copyright 2014-2020 Emmanuel Paradis

## This file is part of the R-package `pegas'.
## See the file ../DESCRIPTION for licensing issues.

geoTrans <- function(x, degsym = NULL, minsym = "'", secsym = "\"")
{
    if (is.null(degsym)) degsym <- "\u00b0"
    x <- as.character(x)
    sow <- grep("[SOW]", x)
    x <- gsub("[SNOWE]", "", x)
    x <- strsplit(x, paste0("[", degsym, minsym, secsym, "]"))
    foo <- function(x) {
        x <- as.numeric(x)
        sum(x[1:3] / c(1, 60, 3600), na.rm = TRUE)
    }
    res <- sapply(x, foo)
    if (length(sow)) res[sow] <- -res[sow]
    res
}

geoTrans2 <- function(lon, lat = NULL, degsym = NULL, minsym = "'",
                      secsym = "\"", dropzero = FALSE, digits = 3, latex = FALSE)
{
    if (is.null(lat)) {
        nc <- ncol(lon)
        if (is.null(nc) || nc < 2)
            stop("if 'lat' is not given, 'lon' should have at least 2 columns")
        lat <- lon[, 2]
        lon <- lon[, 1]
    } else {
        if (length(lon) != length(lat))
            stop("'lat' and 'lon' should have the same length")
    }
    if (is.null(degsym)) degsym <- "\u00b0"
    foo <- function(x) {
        d <- floor(x)
        m2 <- (x - d) * 60
        m <- floor(m2)
        s <- round(60 * (m2 - m), digits = digits)
        if (dropzero) {
            m <- ifelse(m == 0 & s == 0, "", paste0(m, minsym))
            s <- ifelse(s == 0, "", paste0(s, secsym))
        } else {
            m <- paste0(m, minsym)
            s <- paste0(s, secsym)
        }
        d <- paste0(d, degsym)
        paste0(d, m, s)
    }
    x <- foo(lon)
    y <- foo(lat)
    res <- paste0(ifelse(lat < 0, "S ", "N "), y, ", ", ifelse(lon < 0, "W ", "E "), x)
    if (latex) {
        res <- gsub(degsym, "\\\\textdegree ", res)
        res <- gsub("'", "$'$", res)
        res <- gsub("\"", "$''$", res)
    }
    res
}

geod <- function(lon, lat = NULL, R = 6371)
{
    deg2rad <- function(x) x * pi / 180
    if (is.null(lat)) {
        lat <- lon[, 2L]
        lon <- lon[, 1L]
    }
    n <- length(lat)
    lat <- deg2rad(lat)
    lon <- deg2rad(lon)
    absdiff <- function(x, y) abs(x - y)
    Delta_lon <- outer(lon, lon, absdiff)
    Delta_lat <- outer(lat, lat, absdiff)
    tmp <- cos(lat) # store the cosinus(lat) for all individuals
    A <- (sin(Delta_lat / 2))^2 + rep(tmp, n) * rep(tmp, each = n) * (sin(Delta_lon / 2))^2
    R * 2 * asin(sqrt(A))
### alternative:
### tmp <- sin(lat); tmp2 <- cos(lat)
### A <- acos(outer(tmp, tmp) + outer(tmp2, tmp2) * cos(Delta_lon))
### R * A
}

