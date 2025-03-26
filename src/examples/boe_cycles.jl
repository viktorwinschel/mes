"""
Bill of Exchange (BOE) Cycles Example

This example demonstrates:
1. BOE creation and circulation
2. Discounting process
3. Multi-level accounting (micro, meso, macro)
4. Categorical structures in financial flows
"""

using MES
using Dates

# Types and Structures
struct Transaction
    id::String
    timestamp::DateTime
    description::String
    amount::Float64
    from_account::String
    to_account::String
    discount_rate::Float64
    maturity_date::DateTime
    present_value::Float64
end

struct TransactionLog
    transactions::Vector{Transaction}
end

# Discounting Functions
function calculate_present_value(future_value::Float64, rate::Float64, time_to_maturity::Float64)
    return future_value / (1 + rate * time_to_maturity)
end

function calculate_discount(future_value::Float64, present_value::Float64)
    return future_value - present_value
end

# Bill of Exchange Example with Three Levels of Invariance
function bill_of_exchange_example()
    # Micro Level: Individual Transactions
    micro_objects = [
        "Seller", "Buyer", "Seller_Bank", "Buyer_Bank",
        "Seller_Inventory", "Buyer_Inventory",
        "Seller_Receivables", "Buyer_Liabilities"
    ]
    micro_morphisms = Dict(
        # Initial Delivery
        ("Seller_Inventory", "Buyer_Inventory") => ["Physical_Transfer"],
        # BOE Creation
        ("Buyer", "Seller") => ["Create_BOE"],
        ("Buyer_Liabilities", "Seller_Receivables") => ["Record_BOE"],
        # BOE Transfer Chain
        ("Seller", "Seller_Bank") => ["Transfer_BOE"],
        ("Seller_Bank", "Buyer_Bank") => ["Interbank_Transfer"],
        ("Buyer_Bank", "Buyer") => ["Final_Transfer"]
    )
    micro_category = create_category(micro_objects, micro_morphisms)

    # Meso Level: Banking System
    meso_objects = [
        "Banking_Network",
        "Clearing_System",
        "Bank_Positions",
        "Settlement_Accounts"
    ]
    meso_morphisms = Dict(
        # Bank Settlement
        ("Banking_Network", "Clearing_System") => ["Settlement_Process"],
        ("Bank_Positions", "Settlement_Accounts") => ["Position_Update"]
    )
    meso_category = create_category(meso_objects, meso_morphisms)

    # Macro Level: Economic System
    macro_objects = [
        "Economy",
        "Monetary_System",
        "National_Accounts",
        "Reserve_System"
    ]
    macro_morphisms = Dict(
        # Central Bank Settlement
        ("Monetary_System", "Reserve_System") => ["Reserve_Adjustment"],
        # Economic Impact
        ("Economy", "National_Accounts") => ["Economic_Update"]
    )
    macro_category = create_category(macro_objects, macro_morphisms)

    return micro_category, meso_category, macro_category
end

# Transaction Flow with Discounting
function run_boe_example(;
    initial_amount::Float64=10000.0,
    rate::Float64=0.05,
    maturity_months::Int=6)

    # Initialize transaction log
    log = TransactionLog(Transaction[])

    # 1. BOE Creation
    pv = calculate_present_value(initial_amount, rate, maturity_months/12)
    push!(log.transactions, Transaction(
        "BOE_CREATE",
        now(),
        "BOE Creation",
        initial_amount,
        "Buyer_Payables",
        "Seller_Receivables",
        rate,
        now() + Month(maturity_months),
        pv
    ))

    # 2. Bank Acceptance with Discounting
    discount = calculate_discount(initial_amount, pv)
    push!(log.transactions, Transaction(
        "BANK_ACCEPT",
        now(),
        "Bank Acceptance",
        pv,
        "Bank_Liabilities",
        "Seller_Receivables",
        rate,
        now() + Month(maturity_months),
        pv
    ))

    # 3. Monthly Transfers
    for i in 1:maturity_months
        transfer_amount = initial_amount / maturity_months
        current_pv = calculate_present_value(transfer_amount, rate, (maturity_months - i)/12)
        
        push!(log.transactions, Transaction(
            "TRANSFER_$i",
            now() + Month(i-1),
            "Monthly Transfer $i",
            transfer_amount,
            "Buyer_Account",
            "Seller_Account",
            rate,
            now() + Month(maturity_months),
            current_pv
        ))
    end

    # 4. Final Settlement
    push!(log.transactions, Transaction(
        "SETTLE",
        now() + Month(maturity_months),
        "Final Settlement",
        initial_amount,
        "Buyer_Bank",
        "Seller_Bank",
        rate,
        now() + Month(maturity_months),
        initial_amount
    ))

    return log
end

# Example usage and demonstration
function demonstrate_boe_system()
    println("Running Bill of Exchange Example...")
    
    # Create categories
    micro, meso, macro = bill_of_exchange_example()
    println("\nCategories created:")
    println("Micro level objects: ", micro.objects)
    println("Meso level objects: ", meso.objects)
    println("Macro level objects: ", macro.objects)

    # Run BOE example
    log = run_boe_example(
        initial_amount=10000.0,
        rate=0.05,
        maturity_months=6
    )

    println("\nTransaction Log:")
    for t in log.transactions
        println("$(t.timestamp): $(t.description)")
        println("  Amount: $(t.amount)")
        println("  Present Value: $(t.present_value)")
        println("  From: $(t.from_account)")
        println("  To: $(t.to_account)")
        println("  Rate: $(t.discount_rate)")
        println("  Maturity: $(t.maturity_date)")
        println()
    end
end

# Run if this file is executed directly
if endswith(String(PROGRAM_FILE), "boe_cycles.jl")
    demonstrate_boe_system()
end 