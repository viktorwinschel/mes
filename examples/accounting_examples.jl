using MES

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

# Double Entry Accounting Example
function double_entry_example()
    # Micro level: Individual transactions
    micro_objects = ["Debit_Account", "Credit_Account"]
    micro_morphisms = Dict(
        ("Debit_Account", "Credit_Account") => ["Transaction"]
    )
    micro_category = create_category(micro_objects, micro_morphisms)

    # Meso level: Business unit
    meso_objects = ["Business_Unit", "Financial_Statement"]
    meso_morphisms = Dict(
        ("Business_Unit", "Financial_Statement") => ["Aggregation"]
    )
    meso_category = create_category(meso_objects, meso_morphisms)

    # Macro level: Economic system
    macro_objects = ["Economy", "National_Accounts"]
    macro_morphisms = Dict(
        ("Economy", "National_Accounts") => ["Consolidation"]
    )
    macro_category = create_category(macro_objects, macro_morphisms)

    return micro_category, meso_category, macro_category
end

# Example usage
function run_examples()
    println("Running Bill of Exchange Example:")
    micro_bill, meso_bill, macro_bill = bill_of_exchange_example()
    println("\nMicro Level (Individual Transactions):")
    println("Objects: ", micro_bill.objects)
    println("Morphisms: ", micro_bill.morphisms)

    println("\nMeso Level (Banking System):")
    println("Objects: ", meso_bill.objects)
    println("Morphisms: ", meso_bill.morphisms)

    println("\nMacro Level (Economic System):")
    println("Objects: ", macro_bill.objects)
    println("Morphisms: ", macro_bill.morphisms)

    println("\nRunning Double Entry Accounting Example:")
    micro_acc, meso_acc, macro_acc = double_entry_example()
    println("\nMicro Level (Individual Transactions):")
    println("Objects: ", micro_acc.objects)
    println("Morphisms: ", micro_acc.morphisms)

    println("\nMeso Level (Business Unit):")
    println("Objects: ", meso_acc.objects)
    println("Morphisms: ", meso_acc.morphisms)

    println("\nMacro Level (Economic System):")
    println("Objects: ", macro_acc.objects)
    println("Morphisms: ", macro_acc.morphisms)
end

# Run the examples
run_examples()