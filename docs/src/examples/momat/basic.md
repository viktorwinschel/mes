# Basic MOMAT Examples

This page contains basic examples of using MES for Monetary Macro Accounting (MOMAT) modeling.

## Simple Monetary Circuit

```julia
using MES

# Create a simple monetary circuit
circuit = create_monetary_circuit(
    ["Bank", "Firm", "Household"],
    Dict(
        ("Bank", "Firm") => "Loan",
        ("Firm", "Household") => "Wages",
        ("Household", "Firm") => "Consumption",
        ("Firm", "Bank") => "Repayment"
    )
)

# Set initial balances
set_balance!(circuit, "Bank", 1000.0)
set_balance!(circuit, "Firm", 0.0)
set_balance!(circuit, "Household", 0.0)

# Simulate one period
simulate_period!(circuit)

# Print results
println("Final balances:")
for agent in get_agents(circuit)
    println("$agent: $(get_balance(circuit, agent))")
end
```

## Bank Balance Sheets

```julia
# Create a bank with assets and liabilities
bank = create_bank(
    "Bank1",
    Dict(
        "Loans" => 1000.0,
        "Reserves" => 100.0
    ),
    Dict(
        "Deposits" => 800.0,
        "Capital" => 300.0
    )
)

# Create a pattern for the balance sheet
pattern = create_balance_sheet_pattern(bank)

# Calculate key ratios
ratios = calculate_ratios(bank)
println("Capital ratio: $(ratios.capital_ratio)")
println("Liquidity ratio: $(ratios.liquidity_ratio)")
```

## Payment Systems

```julia
# Create a payment system
system = create_payment_system(
    ["Bank1", "Bank2", "Bank3"],
    Dict(
        ("Bank1", "Bank2") => 100.0,
        ("Bank2", "Bank3") => 150.0,
        ("Bank3", "Bank1") => 200.0
    )
)

# Process payments
process_payments!(system)

# Calculate net positions
positions = calculate_net_positions(system)
println("Net positions:")
for (bank, position) in positions
    println("$bank: $position")
end
```

## Memory Components

```julia
# Create a financial memory component
memory = create_financial_memory(
    capacity=100,
    decay_rate=0.1
)

# Store transactions
store_transaction!(memory, "Bank1", "Bank2", 100.0, "Payment")
store_transaction!(memory, "Bank2", "Bank3", 150.0, "Payment")

# Retrieve recent transactions
recent = get_recent_transactions(memory, "Bank1")
println("Recent transactions for Bank1:")
for t in recent
    println("$(t.date): $(t.amount) to $(t.counterparty)")
end
```

## Pattern Recognition

```julia
# Create a pattern recognition system
system = create_pattern_recognition_system(
    threshold=0.7,
    decay_rate=0.1
)

# Add known patterns
add_pattern!(system, ["Bank1", "Bank2", "Bank3"], "Interbank")
add_pattern!(system, ["Firm1", "Bank1", "Household1"], "Credit")

# Recognize patterns in transactions
transactions = [
    ("Bank1", "Bank2", 100.0),
    ("Bank2", "Bank3", 150.0),
    ("Firm1", "Bank1", 200.0)
]

patterns = recognize_patterns(system, transactions)
println("Recognized patterns:")
for pattern in patterns
    println(pattern)
end
``` 