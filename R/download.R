library(R.utils)
library(purrr)
library(dvcr)
library(utils)
library(tools)
library(vroom)
library(arrow)
library(vroom)
library(tibble)
library(data.table)
library(arrow, warn.conflicts = TRUE)
library(XML)
library(dplyr)
library(readr)
library(ontologyIndex)
library(httr)
library(jsonlite)
library(rvest)
library(here)
source(here::here("R/chrome.R"))
library(httr)
library(stringr)
library(tidyverse)
library(dplyr)
library(fs)
library(purrr)
library(rvest)
library(htmlTable)  
library(arsenal)    
library(jsonlite)
library("rdflib")
library("jsonld")
library(purrr)


##----------create dir structure
data_dir <- "data"
download_dir <- "download"
mkdir = function (dir) {
  if (!dir.exists(dir)) {
    dir.create(dir,recursive=TRUE)
  } 
}
map(download_dir,mkdir)


##----------Gene Ontology (GO): Ontology, GO Annotation, GO-CAM data
options(timeout=1800) 
geneOntologyData="http://current.geneontology.org/ontology/go.owl"
geneOntologyDataPlus="http://current.geneontology.org/ontology/extensions/go-plus.owl"
urlGOAnnotation=c("http://geneontology.org/gene-associations/goa_human.gaf.gz","http://geneontology.org/gene-associations/goa_human_complex.gaf.gz","http://geneontology.org/gene-associations/goa_human_isoform.gaf.gz","http://geneontology.org/gene-associations/goa_human_rna.gaf.gz")
urlGOCamDownload="https://s3.amazonaws.com/geneontology-public/gocam/GO-CAMs.ttl.zip"
urls=c(geneOntologyData, geneOntologyDataPlus,urlGOAnnotation,urlGOCamDownload)
files=dir_create(download_dir) |> fs::path(sapply(urls,basename))

walk2(urls,files, download.file)






