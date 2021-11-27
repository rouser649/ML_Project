using CSV
using DataFrames
using Gurobi
using JuMP
using Formatting

all_betas = CSV.read("Data/betas.csv", DataFrame, header = 0)
beta0 = all_betas[1,1]
betas = all_betas[2:64,1]

function opt_visibility(store_mat, M, num_change)

    #### Get the Price ####
    MRP = store_mat[:,9] #Maximum retail price (only price infoi availble in the data set)
    MRP = reshape(MRP, length(MRP), 1)
    
    #### Start the model ####
    model = Model(Gurobi.Optimizer)
    set_optimizer_attribute(model, "OutputFlag", 0) 
    
    #### Dimensions of Data ####
    product, feature = size(store_mat)


    #############################################
    ### Variables ####
    @variable(model, pos_cv[1:product], Bin) #binary for positive change
    @variable(model, neg_cv[1:product], Bin) #binary for negative change
    @variable(model, q[1:product] >= 0) #increased change values
    @variable(model, r[1:product] <= 0) #increased change values
    @variable(model, modified_X[1:product, 1:feature]) #X df that visibility modified
    @variable(model, predicted_demand[1:product]) #predicted demand (using modified X)
    @variable(model, predicted_sales[1:product]) #predicted sales (predicted demand * MRP)
    

    #############################################
    ### Constraints ####
    #All other columns except visibility should be the same as store_mat
    @constraint(model, [f=1:4], modified_X[:,f] .== store_mat[:,f])
    @constraint(model, [f=6:feature], modified_X[:,f] .== store_mat[:,f])

    #Can only have a postive change or a negative change, not both
    @constraint(model, [i=1:product], pos_cv[i] + neg_cv[i] <= 1)

    #### If no pos or negative change, bounded at zero ###
    @constraint(model, [i=1:product], q[i] <= M * pos_cv[i])
    @constraint(model, [i=1:product], r[i] >= -M * neg_cv[i])

    #### Maximum number of things we can change ####
    #1000 is just arbitrary number to signal that we are not restricted how many changes we can do
    if num_change != 1000
        @constraint(model, sum(pos_cv) == num_change)
        @constraint(model, sum(neg_cv) == num_change)
    end


    #Change the visibility
    @constraint(model, [i = 1:product], store_mat[i,5] + q[i] +r[i] == modified_X[i,5])
    #Visiblity cannot be below 0%
    @constraint(model, [i = 1:product], modified_X[i,5] >=0)

    #The total change of visibility must be 0 
    @constraint(model, sum(q) + sum(r) == 0 )


    #Get the predicted demand
    @constraint(model, beta0 .+ modified_X * betas .== predicted_demand)
    #predicted_demand = @expression(model, (beta0 .+ modified_X * betas) )

    #Get prediced sales
    #pred_demand_mat =  reshape(predicted_demand, length(predicted_demand), 1)

    @constraint(model, [i=1:product], MRP[i] * predicted_demand[i] == predicted_sales[i])



    #Maximize predicted sales
    @objective(model, Max, sum(predicted_sales))

    optimize!(model)

    predicted_sales = value.(predicted_sales)
    total_revenue = format(sum(predicted_sales), commas = true)

    neg_cv = value.(neg_cv)
    neg_cv_idx = size(findall(x->x ==1 , neg_cv))

    pos_cv = value.(pos_cv)
    pos_cv_idx = size(findall(x->x ==1 , pos_cv))

    q = value.(q)
    r = value.(r)

    return(total_revenue, neg_cv_idx, pos_cv_idx, q, r)
end

####################################################################################################################################
### Store 13 ####
store_mat_13 = CSV.read("Store/store_13_impute.csv", DataFrame);

#### Unlimited Visibility Changes ####
total_revenue, neg_cv_idx, pos_cv_idx, q, r = opt_visibility(store_mat_13, .05, 1000 )


#### Restrict to no visibility change ####
total_revenue_baseline, neg_cv_idx_baseline, pos_cv_idx_baseline, q_baseline, r_baseline = opt_visibility(store_mat_13, .05, 0 );

#### Restrict to some visiblity change visibility change ####
total_revenue_mid, neg_cv_idx_mid, pos_cv_idx_mid, q_mid, r_mid = opt_visibility(store_mat_13, .05, 50 );


####################################################################################################################################
### Store 13 ####
