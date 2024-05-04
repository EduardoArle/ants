#load packages
library(sf); library(rnaturalearth); library(raster); library(data.table)

#list WDs
wd_occ <- '/Users/carloseduardoaribeiro/Documents/Collaborations/Lucas/Occurrence data/GBIF_data'
wd_checklists <- '/Users/carloseduardoaribeiro/Documents/Global Alien Patterns/Data/Ants'
wd_shp <- '/Users/carloseduardoaribeiro/Documents/Global Alien Patterns/Data/Ants/Bentity2_shapefile_fullres'

### NOTE ### for now I am using only climatic variables, but for ants, soil layers
wd_variables <- '/Users/carloseduardoaribeiro/Documents/CNA/Data/Variables/wc2-5'
### NOTE ### are probably very relevant. Check lit, and talk to Lucas

#make a species list
setwd(wd_occ)
sps_list <- gsub('_', ' ', gsub('.csv', '', list.files()))

#load species records
setwd(wd_occ)
sps_occ <- lapply(list.files(), read.csv, sep = '\t')

#name objects in the list per species
names(sps_occ) <- sps_list


##  Filter occurrences  ## 

# ... eliminate entries with missing coordinates
sps_occ_coo <- lapply(sps_occ,
                      function(x) x[complete.cases(x$decimalLongitude),])
sps_occ_coo2 <- lapply(sps_occ_coo,
                      function(x) x[complete.cases(x$decimalLatitude),])
 
# ... create an sf spatial object of the occurrences
sps_occ_sf <- lapply(sps_occ_coo2,
                     function(x) st_as_sf(x,
                       coords = c('decimalLongitude', 'decimalLatitude')))

# ... eliminate duplicates

# ... ... load one variable to thin the records by the same resolution
setwd(wd_variables)
mean_d_range <- raster('bio2.bil')

# ... ... make ID raster to thin points by variable resolution
ID_raster <- mean_d_range
ID_raster[] <- c(1:length(ID_raster))

# ... ... keep only one record per cell

# ... ... ... make an empty list to populate with thinned occurrences
sps_occ_thin <- list()

# ... ... ... forloop through the process
for(i in 1:length(sps_occ_coo2))
{
  #get cellID value to thin the records to max one per grid cell (variables)
  cellIDs <- extract(ID_raster, sps_occ_sf[[i]])
  
  #include cell value and coordinates into species data
  sps_occ_coo2[[i]]$cellID <- cellIDs
  
  #eliminate duplicated rows
  sps_occ_thin[[i]] <- unique(as.data.table(sps_occ_coo2[[i]]), by = 'cellID')
}

# ... ... name items in list by species
names(sps_occ_thin) <- names(sps_occ_coo2)


##  Prepare reference region polygons  ## 

# ... load checklist table
setwd(wd_checklists)
ants_CL <- read.csv('Final_checklist_ants.csv')

# ... select checklists for each spcss

# ... ... make an empty list to populate with sps CLs
sps_CL <- list()

# ... ... ... forloop through the process
for(i in 1:length(sps_occ_thin))
{
  sps_CL[[i]] <- ants_CL[which(
    ants_CL$gbifDarwinCore == names(sps_occ_thin)[i]),]
}

# ... ... name items in list by species
names(sps_CL) <- names(sps_occ_thin)

unique(sps_CL[[5]]$status)



Bentity2_shapefile_fullres.shx





## Save info from steps for the results  ## 

# ... total GBIF records for each species
n_GBIF <- sapply(sps_occ, nrow)

# ... GBIF records with coordinates for each species
n_GBIF_coords <- sapply(sps_occ_coo2, nrow)

# ... thinned GBIF records for each species
n_GBIF_thin <- sapply(sps_occ_thin, nrow)
