using CSV
using DataFrames
using Gurobi
using JuMP
using Formatting

store_mat = CSV.read("Data/store_13.csv", DataFrame);
all_betas = CSV.read("Data/betas.csv", DataFrame, header = 0)
beta0 = all_betas[1,1]
betas = all_betas[2:64,1]

MRP = store_mat[:,9]
MRP = reshape(MRP, length(MRP), 1)
M = 0.05

model = Model(Gurobi.Optimizer)
    
set_optimizer_attribute(model, "OutputFlag", 0) 

product, feature = size(store_mat)


#############################################
### Variables ####
@variable(model, pos_cv[1:product], Bin)
@variable(model, neg_cv[1:product], Bin)
@variable(model, q[1:product] >= 0) #increased changes
@variable(model, r[1:product] <= 0) #increased changes
@variable(model, modified_X[1:product, 1:feature])
@variable(model, predicted_sales[1:product])
@variable(model, predicted_demand[1:product])


#############################################
### Constraints ####

#All other columns except visibility should be the same as store_mat
@constraint(model, [f=1:4], modified_X[:,f] .== store_mat[:,f])
@constraint(model, [f=6:feature], modified_X[:,f] .== store_mat[:,f])

#Can only have a postive change or a negative change, not both
@constraint(model, [i=1:product], pos_cv[i] + neg_cv[i] <= 1)

@constraint(model, [i=1:product], q[i] <= M * pos_cv[i])
@constraint(model, [i=1:product], r[i] >= -M * neg_cv[i])


#@constraint(model, sum(pos_cv) == 0)
#@constraint(model, sum(neg_cv) == 0)


#Change the visibility
@constraint(model, [i = 1:product], store_mat[i,5] + q[i] +r[i] == modified_X[i,5])
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

####################################################################################################################################
predicted_sales = value.(predicted_sales)
println(format(sum(predicted_sales), commas = true))

neg_cv = value.(neg_cv)
size(findall(x->x ==1 , neg_cv))

r = value.(r)
r[502]

modified_X = value.(modified_X)

pos_cv = value.(pos_cv)
size(findall(x->x ==1 , pos_cv))

q = value.(q)
q[520]


value.(modified_X)

store_mat
