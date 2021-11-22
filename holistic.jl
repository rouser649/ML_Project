using CSV
using DataFrames 
using Gurobi
using JuMP
using Random
using Statistics


wtrain_filepath = "train_processed.csv"
test_filepath = "test_processed.csv"

train = CSV.read(train_filepath, DataFrame)
test = CSV.read(test_filepath, DataFrame)

#12 interaction variables added

n,p = size(train)

###############################

# Motivationo for uncertainy set. 
# Uncertainty on item max retail price.
# Uncertainty on item fat content
# Uncertainty on outlet size.

# Uncertainty on Outlet Sales, missing data on unreported stuff/returns. 
# Uncertainty on visibility. Difficult to accurately know percentage


################################




################################################################
## Get the highly correlated variables ##

cor(train)

cor(train[:,3], train[:,7])

gurobi_env = Gurobi.Env()
#function holistic(M, gamma, k,  X, Y, x_test, y_val)
    #Initialize the model.
    model = Model(with_optimizer(Gurobi.Optimizer, gurobi_env))
    set_optimizer_attribute(model, "OutputFlag", 0)



    #Get dimensions of x_tilda
    n, p = size(X)  

    #set up the variables
    @variable(model, beta[j = 1:p])
    @variable(model, z[j = 1:p], Bin)
    @variable(model, t[j = 1:p] >= 0) #l1 norm


    #sparsity contraint
    @constraint(model, [i = 1:p], -M * z[i] <= beta[i])
    @constraint(model, [i = 1:p], beta[i] <= M*z[i])

    #sparsity contraint 
    @constraint(model, sum(z) <= k)

    groups = correlated_variables(X)
    
    # correlation constraint
    for g in 1:size(groups)[1]
        idx_1 = groups[g,1]
        idx_2 = groups[g,2]
        @constraint(model, z[idx_1] + z[idx_2] <= 1)
    end


    #group sparsity 
    @constraint(model, [i= 1:size(xtrain)[2]], z[4*(i-1)+1] +z[4*(i-1)+2] + z[4*(i-1)+3] + z[4*(i-1)+4] <= 1)

    #Handle the l1 norm
    @constraint(model, [i=1:p], beta[i] <= t[i])
    @constraint(model, [i=1:p], -beta[i] <= t[i])

    #0.5* sum((ytrain - x_tilda * beta).^2)


    ## Objective Function 
    @objective(model, Min, 0.5 * sum((Y - X * beta).^2) + gamma*sum(t))

    optimize!(model)

    betas = value.(beta)

    
    y_pred = x_test * betas 

    #r = r_squared(y_val, y_pred, ytrain)
    r = r_squared(y_val, y_pred, Y)
    
    mse = compute_mse(x_test,y_val, betas )
   
    return(r, betas, objective_value(model), mse)
    
