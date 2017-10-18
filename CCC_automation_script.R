source("K:/AscendKC/Corp/R_and_D/1-USERS/Jennifer Brussow/options.R")

needed_packages <- c("XLConnect")
sapply(needed_packages, load_packages)

#steps for creation
### 1.	Pull all datasets from Report Manager individually using school ID (ex. 14) 
#       and date range (7/1 – 6/30)

#going to read in sample file for now. can add SQL query later if desired.
new_data <- read.xlsx("14.xlsx") %>%
  mutate(Year = lubridate::year(Sys.Date))

old_data <- read.xlsx("Bakersfield 2016.xlsx") %>%
  mutate(Year = lubridate::year(Sys.Date())-1)

### 2.	Copy 2017 “original” file into same-school 2016 “from school” file.
#overwrite names to match old data file
names(new_data)[1:27] <- names(old_data)[1:27]

#put the compatible rows together
synthesized <- bind_rows(old_data[1:27], new_data[1:27])

### 3.	Save new file as “Schoolname_id#_toschool17”. If multiple “original” files 
#       exist for the school (separate file ids, same name), check for them and merge 
#       into the new “to school’ file as well. This is now the working file for the school.
### 4.	Hide two columns (M & N).
### 5.	Delete rows prior to 2015 send out (green color).
### 6.	Delete columns prior to Fall 2014.
### 7.	Create columns for dataset AF and AG as Fall 16 and Spring 17.
### 8.	Copy validation from columns AD/AE and “Paste special => formatting only” 
#       into columns AF and AG.
### 9.	Color all data from 2017 purple.
### 10.	Format all cells from 2017 with ‘all borders’.
### 11.	Extend school ID (column A) through the new data (so all values in column A 
#       should match the school ID used in the file name).
### 12.	Copy formatting in one line of last year’s data, then “Paste special => 
#       formatting only” into all rows of this year’s data (in purple).
### 13.	Re-save and password protect with formula password (include the school id
#        used in the filename).
