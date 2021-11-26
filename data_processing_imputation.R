#Use this file to process

library(readr)
library(dplyr)
library(fastDummies)

############################
#Read in data
Test <- read_csv("Data/Test.csv")
Train <- read_csv("Data/Train.csv")
Test$Item_Outlet_Sales <- 0



preprocessed_data <- rbind(Train, Test)


total_visibility_store <-  preprocessed_data %>%
  group_by(Outlet_Identifier) %>%            
  summarise(total_visibility = sum(Item_Visibility)) %>%
  left_join(num_visibility_zero, by = "Outlet_Identifier")

#Make all the missign visibilities equal to "missin" for julia.
preprocessed_data <-  preprocessed_data %>% 
  mutate(Item_Visibility = ifelse(Item_Visibility ==0, 9999 , Item_Visibility)) %>% 
  mutate(Item_Visibility = ifelse(Item_Visibility == 0, (1 - total_visibility)/num_zero, Item_Visibility )) %>% 
  mutate(Item_Fat_Content = ifelse(Item_Fat_Content == "low fat", "Low Fat",
                                   ifelse(Item_Fat_Content == "LF", "Low Fat",
                                          ifelse(Item_Fat_Content == "reg", "Regular", Item_Fat_Content) ))) %>% #check to see if it did it right?
  mutate(Years_Opened = 2013 - Outlet_Establishment_Year) %>% 
  mutate_at(vars(Item_Weight), ~ifelse(is.na(Item_Weight), 9999, Item_Weight)) %>% 
  mutate_at(vars(Outlet_Size), ~ifelse(is.na(Outlet_Size),"missing", Outlet_Size)) %>% #check to see if it did it right?
  select(-Outlet_Establishment_Year) #delete this column




################################################
### Create Dummies of categorical variables ###

full_data_dummy <-  dummy_cols(preprocessed_data, select_columns = c("Item_Type",
                                                             "Item_Fat_Content",
                                                             "Outlet_Identifier", 
                                                             #"Outlet_Size",
                                                             "Outlet_Location_Type",
                                                             "Outlet_Type")) 


full_data <- full_data_dummy %>% 
  select(-c(Item_Type_Others, Item_Type,
            Item_Fat_Content, `Item_Fat_Content_Low Fat`, 
            Outlet_Identifier, Outlet_Identifier_OUT010,
            Outlet_Location_Type, `Outlet_Location_Type_Tier 1`,
            Outlet_Type, `Outlet_Type_Grocery Store`,
            Item_Identifier,
            Outlet_Size))






write.csv(full_data, "Data/data_preimpute.csv", row.names = F)
