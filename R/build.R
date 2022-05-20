library(R.utils)
library(purrr)
library(dvcr)
library(vroom)
library(arrow)
library(tibble)
library(dplyr)
library(here)
source(here::here("R/chrome.R"))
library(stringr)
library(tidyverse)
library(dplyr)
library(fs)
library(purrr)
library(rdflib)
library(tidyr)
library(readr)

download_dir <- "download"
data_dir <- "data"
mkdir = function (dir) {
  if (!dir.exists(dir)) {
    dir.create(dir,recursive=TRUE)
  } 
}
map(data_dir,mkdir)

##----------Generate n-triples and parquet data from Gene Ontology rdf data
parse_triples<-function(inputRdfFile){
  tmp_file=file.path(data_dir,paste0(str_replace(basename(inputRdfFile),'.owl',"_ntriples.txt")))
  output_file=file.path(data_dir,paste0(basename(inputRdfFile),"_ntriples.parquet"))
  if( !file.exists(output_file)){
  parsedRdfTest=rdflib::rdf_parse(inputRdfFile, format="guess")
  print(paste0("Parsing:",basename(inputRdfFile)))
  rdflib::rdf_serialize(parsedRdfTest, tmp_file,format = "ntriples")
  remove(parsedRdfTest)
  dfInput=vroom::vroom(tmp_file, delim = ",", col_names = FALSE)
  df_triples=dfInput |> rename_at(1, ~"X1")|> mutate(dataCol=str_replace_all(X1,'"',",")) |> filter(!grepl(",",dataCol)) |> separate(dataCol, into=c("Subject","Predicate","Object"),sep = " ") |>
    select(Subject, Predicate, Object) |> mutate(Object=trimws(Object))
  df_literals=dfInput |> mutate(dataCol=str_replace_all(X1,'"',",")) |> filter(grepl(",",dataCol)) |> separate(dataCol, into=c("v1","v2","v3"),sep = ",") |> separate(v1, into=c("Subject","Predicate"), sep = " ") |>
    mutate(Object=paste(v2,v3))|>mutate(Object=str_remove_all(as.character(Object), '\\.')) |> select(Subject, Predicate, Object) |> mutate(Object=trimws(Object))
  df_combined_triples=bind_rows(df_triples, df_literals) |> mutate(Hash=digest::digest(c(Subject, Predicate,Object), algo="md5")) |> mutate(filename=paste0(basename(inputRdfFile)))
  arrow::write_parquet(df_combined_triples,output_file)
  file.remove(tmp_file)}
  else {print(paste0("File Exists:", output_file))}
  }
owlFileList=list.files(download_dir, pattern = 'owl', full.names = TRUE)
sapply(owlFileList, parse_triples)


##----------Process GO Annotation data
sapply(list.files('download', pattern = ".gz",full.names = TRUE), gunzip)
gafFiles=list.files("download", pattern = ".gaf", full.names = TRUE)
colNamesAnnotations<-c("DB","DB Object ID","DB Object Symbol","Qualifier","GO ID","DB:Reference","Evidence Code", "With or From","Aspect","DB Object Name","DB Object Synonym","DB Object Type","DB Object Synonym","Taxon","Date","Assigned By","Annotation Extension","Gene Product Form ID")
read_go_annotations<-function(x) {read_tsv(x, comment = '!', col_names = colNamesAnnotations) |> mutate(filename=basename(x))}
writeParquetDf<-function(inputFile){
  tmpDf<-read_go_annotations(inputFile)
  arrow::write_parquet(tmpDf, file.path(data_dir,paste0(basename(inputFile),".parquet")))
  rm(tmpDf)
}
combineParquet<-function(inputFileList, outputFileName){
  inputListEdit=sapply(inputFileList, list)
  tmpDf<-data.table::rbindlist(lapply(inputListEdit, arrow::read_parquet), fill = TRUE)
  arrow::write_parquet(tmpDf, outputFileName)
  rm(tmpDf)
  lapply(inputListEdit, file.remove)
}  

sapply(gafFiles, writeParquetDf)
gafFileList=list.files('data', pattern = 'gaf.parquet', full.names = TRUE)
combineParquet(gafFileList,'data/goa_human_combined.parquet')

##----------Process GO CAM ttl data
fileTarget=list.files('download', pattern = 'zip',full.names = TRUE)
unzip(fileTarget,exdir=download_dir)
GOCamsFile="download/GO-CAMs.ttl"
GOCamsOutput=paste0(GOCamsFile,".nt")
rdfInfo=rdflib::rdf_parse(GOCamsFile,format = 'turtle')
rdf_serialize(rdfInfo,GOCamsOutput ,format = "ntriples")
parse_triples(GOCamsOutput)


