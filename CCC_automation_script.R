source("K:/AscendKC/Corp/R_and_D/1-USERS/Jennifer Brussow/options.R")

needed_packages <- c("XLConnect", "excel.link")
sapply(needed_packages, load_packages)

#steps for creation
### 1.	Pull all datasets from Report Manager individually using school ID (ex. 14) 
#       and date range (7/1 – 6/30)


#going to read in sample file for now. can add SQL query later if desired.
old_fname <- "Bakersfield 2016.xlsx"
new_fname <- "14.xlsx"
  
new_data <- read.xlsx(new_fname) %>%
  mutate(Year = lubridate::year(Sys.Date()))

old_data <- read.xlsx(old_fname) %>%
  mutate(Year = lubridate::year(Sys.Date())-1)

cols_keep <- c(names(old_data)[1:27], "Year")

school_name <- gsub(" 2016.xlsx", "", old_fname)
school_id <- gsub(".xlsx", "", new_fname)

### 2.	Copy 2017 “original” file into same-school 2016 “from school” file.
#overwrite names to match old data file
names(new_data)[1:27] <- names(old_data)[1:27]

#put the compatible rows together
synthesized <- bind_rows(old_data[cols_keep], new_data[cols_keep]) %>%
  mutate(TEAS.Date = as.Date(TEAS.Date, origin = as.Date("1899-12-30", format = "%Y-%m-%d"))) %>%
  mutate(Birthdate = as.Date(as.numeric(Birthdate), origin = as.Date("1899-12-30", format = "%Y-%m-%d")))

duplicates <- synthesized %>%
  group_by(User.ID) %>%
  filter(length(User.ID) > 1) %>%
  ungroup() %>%
  arrange(User.ID)

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

#set up fname & pw
filename <- paste0(school_name, "_", school_id, "_toschool", lubridate::year(Sys.Date()), ".xlsx")
pw <- paste0("kr76_", school_id)

#apply password on save
xl.save.file(synthesized, filename = filename, row.names = FALSE, col.names = TRUE,
             password = pw)

# eApp <- COMCreate("Excel.Application") 
# wk <- eApp$Workbooks()$Open(Filename="file.xlsx") 
# wk$SaveAs(Filename="file.xlsx", Password="mypassword")
