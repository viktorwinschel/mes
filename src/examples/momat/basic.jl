"""
Basic MOMAT Examples

This module contains basic examples of using MES for Monetary Macro Accounting (MOMAT) modeling.
"""

using MES
using Dates

# Example 1: Simple Monetary Circuit
function example_monetary_circuit()
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

    return circuit
end

# Example 2: Bank Balance Sheets
function example_bank_balance_sheet()
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

    return bank, pattern, ratios
end

# Example 3: Payment Systems
function example_payment_system()
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

    return system, positions
end

# Example 4: Memory Components
function example_financial_memory()
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

    return memory, recent
end

# Example 5: Pattern Recognition
function example_pattern_recognition()
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

    return system, patterns
end

# Run all examples
function run_basic_examples()
    println("Running basic MOMAT examples...")

    println("\n1. Monetary Circuit:")
    circuit = example_monetary_circuit()
    println("Final balances:")
    for agent in get_agents(circuit)
        println("$agent: $(get_balance(circuit, agent))")
    end

    println("\n2. Bank Balance Sheet:")
    bank, pattern, ratios = example_bank_balance_sheet()
    println("Capital ratio: $(ratios.capital_ratio)")
    println("Liquidity ratio: $(ratios.liquidity_ratio)")

    println("\n3. Payment System:")
    system, positions = example_payment_system()
    println("Net positions:")
    for (bank, position) in positions
        println("$bank: $position")
    end

    println("\n4. Financial Memory:")
    memory, recent = example_financial_memory()
    println("Recent transactions for Bank1:")
    for t in recent
        println("$(t.date): $(t.amount) to $(t.counterparty)")
    end

    println("\n5. Pattern Recognition:")
    system, patterns = example_pattern_recognition()
    println("Recognized patterns:")
    for pattern in patterns
        println(pattern)
    end
end