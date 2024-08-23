#I did initially this with a graphical tool called pavian:https://fbreitwieser.shinyapps.io/pavian/  but the present script will allow you to make it with R

args <- commandArgs(TRUE)


######1) Parsing of the kraken2 reports to extract the % (relative to the total number of reads) of unclassifed, human, bacteria and fungi

#Folder where the kraken2 reports are saved, this is the first argument in the snakemake command
ff <- args[1]

###Main function to parse the reports in each of the folders and extract the taxa of interest
Kraken2_report_to_csv <- function(folder,V){
#Creation of an empty dataframe to store the output of the parsing. This should contain the same number of rows as files in the folder and the number of taxa of interest, as number of columns
df <- data.frame(matrix(ncol = 4 , nrow = length(list.files(folder, pattern = ".report.txt", full.names = TRUE))))
#The taxa of interest (this will be the column names)
colnames(df) <- c("unclassified","Human","Fungi","Bacteria")


#The list of files in the folder that are reports
files <- list.files(folder, pattern = ".report.txt", full.names = TRUE)

rownames(df) <- gsub("gpfs/.*/","",files)
rownames(df) <- gsub("/","",rownames(df))
rownames(df) <- gsub(".report.txt","",rownames(df))

#for each of the files
for (i in files) {
  #read the file
  file <- read.delim(i, header=FALSE)
  #save the name that will be used to save the data
  name <- gsub("gpfs/.*/","",i)
  name <- gsub("/","",name)
  name <- gsub(".report.txt","",name)
  
  #for each of the rows in the file
  for (r in 1:nrow(file)) {
    #extract the taxa
    tax <- gsub(" ", "", file[r, "V6"])
    print (tax)
    #if is the taxa of intrest
  if (tax == "Bacteria") {
    #save it in the dataframe
    df[name,"Bacteria"] <- file[r,V]
   # rm(file)
  } 
    
  else if (tax == "unclassified") {
    df[name,"unclassified"] <- file[r,V]
  } 
    
  else if (tax == "Homosapiens") {
    df[name,"Human"] <- file[r,V]
  } 
  
  else if (tax == "Fungi") {
    df[name,"Fungi"] <- file[r,V]
  }
    
  }}
write.csv(df,args[2]) ##This is a summary of the bacteria, unclassified, human and fungal reads, saved in the same folder where the reports are, indicated with the second argument in the snakemake rule

}

#percentatge (this is normalized by the total number of reads)
Kraken2_report_to_csv(ff,"V1") 