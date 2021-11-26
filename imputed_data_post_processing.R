#Read in the CSV of optimally imputed data from Julia


Optimal_Impute_Data <- read_csv("Data/Optimal_Impute_Data.csv")



#Interaction Variables
#do we need to center these first?

full_data =Optimal_Impute_Data%>%
  #mutate(Outlet_Size_Household=Outlet_Size_Medium*Item_Type_Household) %>% 
  #mutate(Outlet_Size_Hygiene=Outlet_Size_Medium*(`Item_Type_Health and Hygiene`)) %>% 
  #mutate(Outlet_Size_Drinks=Outlet_Size_Medium*(`Item_Type_Hard Drinks`)) %>% 
  
  #mutate(Outlet_Size_Age=Outlet_Size_Medium*Years_Opened) %>% 
  mutate(Outlet_Age_Hyg=Years_Opened*(`Item_Type_Health and Hygiene`)) %>% 
  mutate(Outlet_Age_Drinks=Years_Opened*(`Item_Type_Hard Drinks`)) %>% 
  
  
  #mutate(Outlet_Size_FruitVeg=Outlet_Size_Medium*(`Item_Type_Fruits and Vegetables`)) %>% 
  #mutate(Outlet_Size_Item_Everyday=Outlet_Size_Medium*(`Item_Type_Fruits and Vegetables`)*Item_Type_Dairy*Item_Type_Breads) %>% 
  
  
  mutate(Supermarket_Item_Everyday=(`Outlet_Type_Supermarket Type1`)*(`Item_Type_Fruits and Vegetables`)*Item_Type_Dairy*Item_Type_Breads) %>% 
  mutate(Supermarket_Item_Drinks=(`Outlet_Type_Supermarket Type1`)*(`Item_Type_Hard Drinks`))%>% 
  mutate(Supermarket_Item_Household=(`Outlet_Type_Supermarket Type1`)*Item_Type_Household) %>% 
  mutate(Supermarket_Item_Hygiene=(`Outlet_Type_Supermarket Type1`)*(`Item_Type_Health and Hygiene`) ) %>% 
  
  mutate(Weight_Visibility = (Item_Weight * Item_Visibility),
         Weight_MRP = Item_Weight * Item_MRP,
         Visibility_MRP = Item_Visibility * Item_MRP)    


#Recover the true train and true test
train_processed <- full_data[1:nrow(Train),]
test_processed <- full_data[(nrow(Train)+1):nrow(full_data),]



write_csv(train_processed, file = "Data/train_val_optimpute.csv") #This will be read into stable reg impute
write_csv(test_processed, file = "Data/test_from_train_optimpute.csv")

