# Install required R packages.

#writeLines('PATH="${C:/Users/coche/Documents/R/win-library/4.0/rtools40}\\usr\\bin;${PATH}"', con = "~/.Renviron")

install.packages("bupaR")
install.packages("edeaR")
install.packages("eventdataR")
install.packages("ggplot2")
install.packages("petrinetR")
install.packages("processmapR")
install.packages("xesreadR")
install.packages("pm4py")
install.packages("heuristicsmineR") 
#setwd("/Users/coche/Documents/R/win-library/4.0")
#install.packages("pMineR_0.31.tar.gz", repos = NULL, type ="source") 

# Load required R packages.

library(anytime)
library(bupaR)
library(ggplot2)
library(processmapR)
library(dplyr)
library(pm4py)
library(heuristicsmineR)
library(pMineR)

# Set the working directory.

setwd("/Users/coche/Desktop/tfg/R ANALYSES/My_R_code")

# Check the working directory

getwd()

# Set TimeZone to UCT.

Sys.setenv(TZ='UTC')

# Read activities CSVs into R.

MOOC1 <- read.csv(file = "csv/v3/mooc1_v3.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)
MOOC2 <- read.csv(file = "csv/v3/mooc2_v3.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)

# Check classes of columns of HANDSON3.csv file. This is important because data types may not work with some libraries.

sapply(MOOC1, class)

# Show first top records of the HANDSON3.csv file.

head(MOOC1)

# Convert to time type the datetime column.

MOOC1$timestamp <- anytime(MOOC1$timestamp)
MOOC2$timestamp <- anytime(MOOC2$timestamp)

# Show first top records of the HANDSON3.csv file.

head(MOOC1$timestamp)

# Check classes of columns of HANDSON3.csv file. This is important because data types may not work with some libraries.

sapply(MOOC1, class)

# Add a new column "instance" to HANDSON3.csv file. This is column represent the instances of the activities.

MOOC1$instance <- 1:nrow(MOOC1)
MOOC2$instance <- 1:nrow(MOOC2)

# Add a new column "status" to HANDSON3.csv file. This is column represent the instances of the activities.

MOOC1$status <- "complete"
MOOC2$status <- "complete"

# Create event logs

EventLog1 <- MOOC1 %>% #a dataframe with the information in the table above
  eventlog(
    case_id = "performed_by_guid",
    activity_id = "event",
    activity_instance_id = "instance",
    lifecycle_id = "status",
    timestamp = "timestamp",
    resource_id = "owner_guid"
  )

EventLog2 <- MOOC2 %>%
  eventlog(
    case_id = "performed_by_guid",
    activity_id = "event",
    activity_instance_id = "instance",
    lifecycle_id = "status",
    timestamp = "timestamp",
    resource_id = "owner_guid"
  )

# Print summary for the EventLog file.

summary(EventLog1)

# Process map from the ProcesMapR package

EventLog1 %>%
  process_map(type = frequency("absolute"))

EventLog2 %>%
  process_map(type = frequency("absolute"))

# mean time between actions in process map form

EventLog1 %>%
  process_map(type = performance())

EventLog2 %>%
  process_map(type = performance())

# Process matrix at level performance shows the mean time between actions in matrix form

EventLog1 %>%
  process_matrix(type = performance()) %>%
  plot

EventLog2 %>%
  process_matrix(type = performance()) %>%
  plot

# Percentage of cases where an activity is present

EventLog1 %>% 
  activity_presence() %>%
  plot

EventLog2 %>% 
  activity_presence() %>%
  plot

# dotted chart shows each event by each case user against time

EventLog1 %>%
  filter_time_period(interval = ymd(c(20140519, 20140520)), filter_method = "contained") %>%
  dotted_chart(x = "absolute", y = "start", color="event")

EventLog2 %>%
  filter_time_period(interval = ymd(c(20141028, 20141228)), filter_method = "contained") %>%
  dotted_chart(x = "absolute", y = "start", color="event")

# pMineR process tree

# instantiate an object from the class 'dataLoader'
DL.obj <- dataLoader()

# let's load a dummy dataset
DL.obj$load.csv(nomeFile = "csv/v3/mooc1_v3.csv",
                IDName = "performed_by_guid",
                EVENTName = "event",
                dateColumnName = "timestamp",sep = ",",
                format.column.date = "%Y-%m-%d %H:%M:%S")

obj.MM <- firstOrderMarkovModel(parameters.list = list("threshold"=.01))

# load the data set into obj.MM
obj.MM$loadDataset( dataList = DL.obj$getData() )

obj.MM$train()

obj.MM$plot()
