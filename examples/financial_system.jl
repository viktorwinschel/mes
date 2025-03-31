using Pkg
Pkg.activate(".")
using MES

# Create a simple financial system with two agents: a company and a bank

# First, create the agents
company = Agent("COMPANY", "COMPANY", ["BANK", "LOAN", "GOOD"])
bank = Agent("BANK", "BANK", ["COMPANY_LOAN", "COMPANY_BANK"])

# Create accounts for each agent
company_bank = Account("COMPANY_BANK", "COMPANY", "BANK", 1000.0)
company_loan = Account("COMPANY_LOAN", "COMPANY", "LOAN", -500.0)
company_good = Account("COMPANY_GOOD", "COMPANY", "GOOD", 0.0)

bank_company_loan = Account("BANK_COMPANY_LOAN", "BANK", "COMPANY_LOAN", 500.0)
bank_company_bank = Account("BANK_COMPANY_BANK", "BANK", "COMPANY_BANK", -1000.0)

# Create a flow for loan payment
loan_payment = Flow("LOAN_PAYMENT", "PAYMENT", "COMPANY", "BANK", 100.0)

# Create a financial category with these objects
objects = [company, bank, company_bank, company_loan, company_good,
    bank_company_loan, bank_company_bank, loan_payment]

# Create transactions
transactions = [
    Transaction("loan_payment", company_bank, bank_company_bank, 100.0, "PAYMENT"),
    Transaction("loan_interest", company_bank, bank_company_bank, 10.0, "PAYMENT")
]

# Create a financial category
financial_cat = create_financial_category(
    DataFrame(
        Dict(
            "COMPANY_BANK" => [1000.0],
            "COMPANY_LOAN" => [-500.0],
            "COMPANY_GOOD" => [0.0],
            "BANK_COMPANY_LOAN" => [500.0],
            "BANK_COMPANY_BANK" => [-1000.0],
            "FLOW_PAYMENT_LOAN_PAYMENT" => [100.0],
            "FLOW_PAYMENT_LOAN_INTEREST" => [10.0]
        )
    ),
    1
)

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

# Create a pattern showing the loan relationship
loan_pattern = create_pattern(
    financial_cat,
    ["COMPANY_BANK", "BANK_COMPANY_BANK"],
    [("COMPANY_BANK", "BANK_COMPANY_BANK", "loan_payment")]
)

# Verify the pattern
println("\nVerifying loan pattern:")
println("Pattern validity: ", verify_pattern(loan_pattern))

# Calculate and verify the colimit
colimit_obj, colimit_morphisms = calculate_colimit(loan_pattern)
println("\nColimit object: ", colimit_obj)
println("Colimit morphisms: ", colimit_morphisms)
println("Colimit validity: ", verify_colimit(loan_pattern, colimit_obj, colimit_morphisms))

println("\nFinancial system example completed successfully!")