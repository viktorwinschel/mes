# Getting Started with MES

This guide will help you get started with using the Memory Evolutive Systems (MES) package in Julia.

## Installation

To install the MES package, you can use the Julia package manager:

```julia
using Pkg
Pkg.add("MES")
```

## Basic Usage

### Simple Economic System Example

Here's a complete example showing how to create and work with a simple economic system using MES:

```julia
using Pkg
Pkg.activate(".")
using MES
using DataFrames

# Create a simple economy with three agents: company, bank, and household
company = Agent("COMPANY", "COMPANY", ["BANK", "LOAN", "GOOD"])
bank = Agent("BANK", "BANK", ["COMPANY_LOAN", "COMPANY_BANK", "HOUSEHOLD"])
household = Agent("HOUSEHOLD", "HOUSEHOLD", ["BANK", "LABOR", "GOOD"])

# Create accounts for each agent
# Company accounts
company_bank = Account("COMPANY_BANK", "COMPANY", "BANK", 1000.0)
company_loan = Account("COMPANY_LOAN", "COMPANY", "LOAN", -500.0)
company_good = Account("COMPANY_GOOD", "COMPANY", "GOOD", 0.0)

# Bank accounts
bank_company_loan = Account("BANK_COMPANY_LOAN", "BANK", "COMPANY_LOAN", 500.0)
bank_company_bank = Account("BANK_COMPANY_BANK", "BANK", "COMPANY_BANK", -1000.0)
bank_household = Account("BANK_HOUSEHOLD", "BANK", "HOUSEHOLD", -500.0)

# Household accounts
household_bank = Account("HOUSEHOLD_BANK", "HOUSEHOLD", "BANK", 500.0)
household_labor = Account("HOUSEHOLD_LABOR", "HOUSEHOLD", "LABOR", 100.0)
household_good = Account("HOUSEHOLD_GOOD", "HOUSEHOLD", "GOOD", 0.0)

# Create flows for transactions
wage_payment = Flow("WAGE_PAYMENT", "PAYMENT", "COMPANY", "HOUSEHOLD", 100.0)
loan_payment = Flow("LOAN_PAYMENT", "PAYMENT", "COMPANY", "BANK", 50.0)
good_purchase = Flow("GOOD_PURCHASE", "PURCHASE", "HOUSEHOLD", "COMPANY", 80.0)

# Create transactions
transactions = [
    Transaction("wage_payment", company_bank, household_bank, 100.0, "PAYMENT"),
    Transaction("loan_payment", company_bank, bank_company_bank, 50.0, "PAYMENT"),
    Transaction("good_purchase", household_bank, company_bank, 80.0, "PURCHASE")
]

# Create a financial category with initial balances
financial_cat = create_financial_category(
    DataFrame(
        Dict(
            "COMPANY_BANK" => [1000.0],
            "COMPANY_LOAN" => [-500.0],
            "COMPANY_GOOD" => [0.0],
            "BANK_COMPANY_LOAN" => [500.0],
            "BANK_COMPANY_BANK" => [-1000.0],
            "BANK_HOUSEHOLD" => [-500.0],
            "HOUSEHOLD_BANK" => [500.0],
            "HOUSEHOLD_LABOR" => [100.0],
            "HOUSEHOLD_GOOD" => [0.0],
            "FLOW_PAYMENT_WAGE_PAYMENT" => [100.0],
            "FLOW_PAYMENT_LOAN_PAYMENT" => [50.0],
            "FLOW_PURCHASE_GOOD_PURCHASE" => [80.0]
        )
    ),
    1
)

# Add morphisms to the category
for trans in transactions
    add_morphism!(financial_cat, trans)
end

# Add identity morphisms for each object
objects = [company, bank, household, 
          company_bank, company_loan, company_good,
          bank_company_loan, bank_company_bank, bank_household,
          household_bank, household_labor, household_good,
          wage_payment, loan_payment, good_purchase]

for obj in objects
    id_morphism = Transaction("id_$(obj.name)", obj, obj, 0.0, "IDENTITY")
    add_morphism!(financial_cat, id_morphism)
    financial_cat.identity[obj] = id_morphism
end

# Add simple objects for pattern creation
simple_objects = [
    SimpleObject("COMPANY_BANK"),
    SimpleObject("HOUSEHOLD_BANK"),
    SimpleObject("BANK_COMPANY_BANK")
]

for obj in simple_objects
    push!(financial_cat.objects, obj)
    id_morphism = SimpleMorphism("id_$(obj.name)", obj, obj)
    add_morphism!(financial_cat, id_morphism)
    financial_cat.identity[obj] = id_morphism
end

# Verify the category properties
println("Verifying category properties:")
println("Composition closure: ", verify_composition_closure(financial_cat))
println("Identity existence: ", verify_identity_existence(financial_cat))
println("Associativity: ", verify_associativity(financial_cat))
println("Identity laws: ", verify_identity_laws(financial_cat))

# Verify conservation laws
conservation = verify_conservation_laws(financial_cat)
println("\nVerifying conservation laws:")
println("Bank balance conservation: ", conservation.bank_balance)
println("Loan balance conservation: ", conservation.loan_balance)

# Create patterns for different relationships
wage_pattern = create_pattern(
    financial_cat,
    ["COMPANY_BANK", "HOUSEHOLD_BANK"],
    [("COMPANY_BANK", "HOUSEHOLD_BANK", "wage_payment")]
)

loan_pattern = create_pattern(
    financial_cat,
    ["COMPANY_BANK", "BANK_COMPANY_BANK"],
    [("COMPANY_BANK", "BANK_COMPANY_BANK", "loan_payment")]
)

trade_pattern = create_pattern(
    financial_cat,
    ["HOUSEHOLD_BANK", "COMPANY_BANK"],
    [("HOUSEHOLD_BANK", "COMPANY_BANK", "good_purchase")]
)

# Verify the patterns
println("\nVerifying patterns:")
println("Wage pattern validity: ", verify_pattern(wage_pattern))
println("Loan pattern validity: ", verify_pattern(loan_pattern))
println("Trade pattern validity: ", verify_pattern(trade_pattern))

# Calculate and verify the colimits
println("\nCalculating colimits:")
for (name, pattern) in [("Wage", wage_pattern), ("Loan", loan_pattern), ("Trade", trade_pattern)]
    colimit_obj, colimit_morphisms = calculate_colimit(pattern)
    println("\n$name pattern colimit:")
    println("Colimit object: ", colimit_obj)
    println("Colimit morphisms: ", colimit_morphisms)
    println("Colimit validity: ", verify_colimit(pattern, colimit_obj, colimit_morphisms))
end
```

This example demonstrates:

1. Creating agents (company, bank, household)
2. Setting up accounts for each agent
3. Defining flows and transactions
4. Creating a financial category
5. Adding morphisms and identity morphisms
6. Verifying category properties
7. Checking conservation laws
8. Creating and verifying patterns
9. Calculating colimits

The example shows how to model a simple economic system with:
- Wage payments from company to household
- Loan payments from company to bank
- Good purchases from household to company

Each relationship is represented as a pattern in the category, and we can verify the mathematical properties of these relationships using the category theory tools provided by MES.

### Key Concepts

The example above introduces several key concepts in MES:

1. **Agents**: Represent economic actors (company, bank, household)
2. **Accounts**: Track balances for different types of assets/liabilities
3. **Flows**: Represent economic transactions between agents
4. **Transactions**: Morphisms that connect accounts through flows
5. **Patterns**: Represent relationships between objects in the category
6. **Colimits**: Mathematical constructs that represent the "gluing" of patterns

### Next Steps

After understanding this basic example, you can:

1. Add more complex patterns and relationships
2. Implement state transitions to simulate the economy over time
3. Add more sophisticated conservation laws
4. Explore the memory system features
5. Work with hierarchical categories

For more advanced examples and detailed API documentation, see the [API Reference](api.md). 