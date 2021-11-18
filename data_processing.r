#Use this file to process

library(readr)
library(dplyr)
library(fastDummies)

############################
#Read in data
Test <- read_csv("Test.csv")
Train <- read_csv("Train.csv")
Test$Item_Outlet_Sales <- 0


preprocessed_data <- rbind(Train, Test)
############################
#Process Data

#Identify the number of zero visibilities for each store
num_visibility_zero <- preprocessed_data %>%
  group_by(Outlet_Identifier) %>%
  summarise(num_zero = length(which(Item_Visibility == 0)))

#Total visibility in each store so far            
total_visibility_store <-  preprocessed_data %>%
    group_by(Outlet_Identifier) %>%            
    summarise(total_visibility = sum(Item_Visibility)) %>%
    left_join(num_visibility_zero, by = "Outlet_Identifier")




getmode <- function(v) {
  uniqv <- unique(v)
  uniqv[which.max(tabulate(match(v, uniqv)))]
}

#Naively mutate visibility for all visibility == 0 
#Clean data errors for item fat content
full_data <- preprocessed_data %>% 
  left_join(total_visibility_store, by = "Outlet_Identifier") %>%
  mutate(Item_Visibility = ifelse(Item_Visibility == 0, (1 - total_visibility)/num_zero, Item_Visibility )) %>% 
  mutate(Item_Fat_Content = ifelse(Item_Fat_Content == "low fat", "Low Fat",
                                   ifelse(Item_Fat_Content == "LF", "Low Fat",
                                          ifelse(Item_Fat_Content == "reg", "Regular", Item_Fat_Content) ))) %>% 
  mutate_at(vars(Item_Weight), ~ifelse(is.na(Item_Weight), mean(Item_Weight, na.rm = TRUE), Item_Weight)) %>% 
  mutate_at(vars(Outlet_Size), ~ifelse(is.na(Outlet_Size), getmode(preprocessed_data$Outlet_Size), Outlet_Size)) %>% #check to see if it did it right?
  mutate(Years_Opened = 2013 - Outlet_Establishment_Year) %>% 
  select(-Outlet_Establishment_Year) #delete this column 


getmode(preprocessed_data$Outlet_Size)

mode(full_data$Outlet_Size)
unique(full_data$Outlet_Size)

############################
## Adding Dummies ###

full_data_dummy <-  dummy_cols(full_data, select_columns = c("Item_Type",
                                                "Item_Fat_Content",
                                                "Outlet_Identifier", 
                                                "Outlet_Size",
                                                "Outlet_Location_Type",
                                                "Outlet_Type")) 
full_data <- full_data_dummy %>% 
  select(-c(Item_Type_Others, Item_Type,
            Item_Fat_Content, `Item_Fat_Content_Low Fat`, 
            Outlet_Identifier, Outlet_Identifier_OUT010,
            Outlet_Size, Outlet_Size_Small,
            Outlet_Location_Type, `Outlet_Location_Type_Tier 1`,
            Outlet_Type, `Outlet_Type_Grocery Store`))



########################################################
## Verifying that the processing worked well ##

#Here are number of missing values in each column 
colSums(is.na(preprocessed_data))

#it looks like item weight and outlet size have missing values

#Item type looks good
unique(preprocessed_data$Item_Type)
unique(preprocessed_data$Item_Fat_Content)


#Visibility before and after naive imputation
test_visibility_sum <- preprocessed_data %>%
  group_by(Outlet_Identifier) %>%            
  summarise(total_visibility = sum(Item_Visibility)) 

full_data_visibility_sum <- full_data %>%
  group_by(Outlet_Identifier) %>%            
  summarise(total_visibility = sum(Item_Visibility)) 

full_data_visibility_sum
########################################################

#Interaction Variables
#do we need to center these first?

full_data =full_data%>%
mutate(Outlet_Size_Household=Outlet_Size_Medium*Item_Type_Household) %>% 
mutate(Outlet_Size_Hygiene=Outlet_Size_Medium*(`Item_Type_Health and Hygiene`)) %>% 
mutate(Outlet_Size_Drinks=Outlet_Size_Medium*(`Item_Type_Hard Drinks`)) %>% 

mutate(Outlet_Size_Age=Outlet_Size_Medium*Years_Opened) %>% 
mutate(Outlet_Age_Hyg=Years_Opened*(`Item_Type_Health and Hygiene`)) %>% 
mutate(Outlet_Age_Drinks=Years_Opened*(`Item_Type_Hard Drinks`)) %>% 


mutate(Outlet_Size_FruitVeg=Outlet_Size_Medium*(`Item_Type_Fruits and Vegetables`)) %>% 
mutate(Outlet_Size_Item_Everyday=Outlet_Size_Medium*(`Item_Type_Fruits and Vegetables`)*Item_Type_Dairy*Item_Type_Breads) %>% 


mutate(Supermarket_Item_Everyday=(`Outlet_Type_Supermarket Type1`)*(`Item_Type_Fruits and Vegetables`)*Item_Type_Dairy*Item_Type_Breads) %>% 
mutate(Supermarket_Item_Drinks=(`Outlet_Type_Supermarket Type1`)*(`Item_Type_Hard Drinks`))%>% 
mutate(Supermarket_Item_Household=(`Outlet_Type_Supermarket Type1`)*Item_Type_Household) %>% 
mutate(Supermarket_Item_Hygiene=(`Outlet_Type_Supermarket Type1`)*(`Item_Type_Health and Hygiene`) )




write_csv(full_data, file="procesed_data")