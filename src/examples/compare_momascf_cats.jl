using Pkg
Pkg.activate(".")

using DataFrames
using CSV
using Dates
using Statistics

# Import MoMaSCF and categorical machinery
include("../MOMA/examples/national_accounting/momascf.jl")
include("../core/category.jl")

# Read MoMaSCF data
df_momascf = CSV.read("simulation_data/data_full.csv", DataFrame)

# Create categorical simulation
categories = create_time_series_functor(df_momascf)
price_transformation = create_price_natural_transformation(df_momascf)

# Function to extract data from categorical simulation
function extract_categorical_data(categories::Dict{Int,FinancialCategory})
    # Initialize DataFrame with same structure as MoMaSCF
    df_cats = DataFrame()

    # Get all column names from first period
    first_period = categories[1]
    for obj in first_period.objects
        if obj isa Account
            df_cats[!, Symbol(obj.name)] = Float64[]
        elseif obj isa Flow
            df_cats[!, Symbol(obj.name)] = Float64[]
        end
    end

    # Add efficiency columns
    df_cats[!, :morning_efficiency] = Float64[]
    df_cats[!, :evening_efficiency] = Float64[]

    # Add period column
    df_cats[!, :Period] = Int[]

    # Fill data from categories
    for period in sort(collect(keys(categories)))
        cat = categories[period]

        # Create row data
        row_data = Dict{Symbol,Float64}()
        row_data[:Period] = period

        # Extract account balances
        for obj in cat.objects
            if obj isa Account
                row_data[Symbol(obj.name)] = obj.balance
            elseif obj isa Flow
                row_data[Symbol(obj.name)] = obj.value
            end
        end

        # Add efficiency values
        row_data[:morning_efficiency] = 0.85  # Default value
        row_data[:evening_efficiency] = 0.90  # Default value

        # Add row to DataFrame
        push!(df_cats, row_data)
    end

    return df_cats
end

# Extract categorical data
df_cats = extract_categorical_data(categories)

# Function to compare DataFrames
function compare_dataframes(df1::DataFrame, df2::DataFrame)
    println("\nDataFrame Comparison:")
    println("====================")

    # Check dimensions
    println("Dimensions:")
    println("MoMaSCF: ", size(df1))
    println("Categorical: ", size(df2))

    # Check column names
    println("\nColumn Names:")
    println("MoMaSCF columns: ", names(df1))
    println("Categorical columns: ", names(df2))

    # Compare values for each column
    println("\nValue Comparisons:")
    for col in intersect(names(df1), names(df2))
        if eltype(df1[!, col]) <: Number
            max_diff = maximum(abs.(df1[!, col] - df2[!, col]))
            mean_diff = mean(abs.(df1[!, col] - df2[!, col]))
            println("\n$col:")
            println("  Maximum difference: ", max_diff)
            println("  Mean difference: ", mean_diff)
            println("  Correlation: ", cor(df1[!, col], df2[!, col]))
        end
    end
end

# Compare the data
compare_dataframes(df_momascf, df_cats)

# Save categorical simulation results
timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
CSV.write("simulation_data/categorical_data_$(timestamp).csv", df_cats)

# Print verification results for each period
println("\nConservation Law Verification:")
println("=============================")
for period in sort(collect(keys(categories)))
    cat = categories[period]
    results = verify_conservation_laws(cat)
    println("\nPeriod $period:")
    println("  Bank balance conservation: ", results.bank_balance)
    println("  Loan balance conservation: ", results.loan_balance)
end