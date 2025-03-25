# Bill of Exchange System

This example demonstrates a complete bill of exchange (BOE) transaction in a double-entry system with multiple agents, including discounting and transaction logging.

## System Components

### Types and Structures
```julia
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
```

### Discounting Functions
```julia
function calculate_present_value(future_value::Float64, rate::Float64, time_to_maturity::Float64)
    return future_value / (1 + rate * time_to_maturity)
end

function calculate_discount(future_value::Float64, present_value::Float64)
    return future_value - present_value
end
```

## Agents and Accounts

### 1. Seller (S)
- Products (inventory)
- Receivables
- Bank account at bankS
- Discount account

### 2. Buyer (B)
- Products (inventory)
- Payables
- Bank account at bankB
- Discount account

### 3. Seller's Bank (bankS)
- Assets
- Liabilities
- Reserves at CB
- Discount account

### 4. Buyer's Bank (bankB)
- Assets
- Liabilities
- Reserves at CB
- Discount account

### 5. Central Bank (CB)
- Assets
- Liabilities (reserves)
- Money supply
- Discount account

## Transaction Flow with Discounting

### 1. BOE Creation
```julia
# Create receivables and payables with present value
pv = calculate_present_value(initial_amount, rate, maturity_months/12)
"create_boe" => (
    ("S_receivables", "B_payables"),
    (amount, rate, time) -> calculate_present_value(amount, rate, time)
)
```

### 2. Bank Acceptance with Discounting
```julia
# Bank accepts BOE with discount calculation
pv, discount = calculate_present_value(initial_amount, rate, maturity_months/12),
              calculate_discount(initial_amount, pv)
"bankS_accept" => (
    ("bankS_liabilities", "S_receivables"),
    (amount, rate, time) -> begin
        pv = calculate_present_value(amount, rate, time)
        discount = calculate_discount(amount, pv)
        (pv, discount)
    end
)
```

### 3. Monthly Transfers
```julia
# Monthly transfers with present value calculation
transfer_amount = initial_amount / maturity_months
pv = calculate_present_value(transfer_amount, rate, (maturity_months - i)/12)
```

### 4. Final Settlement
```julia
# Settlement with present value at maturity
pv = calculate_present_value(initial_amount, rate, 0)
```

## Running the Example

```julia
using MES

# Run example with default parameters
final_state, transaction_log = run_boe_example(
    initial_amount = 10000.0,  # BOE amount
    rate = 0.05,              # Discount rate
    maturity_months = 6        # Time to maturity
)

# Print transaction log
println("\nTransaction Log:")
for t in transaction_log.transactions
    println("$(t.timestamp): $(t.description)")
    println("  Amount: $(t.amount)")
    println("  Present Value: $(t.present_value)")
    println("  From: $(t.from_account)")
    println("  To: $(t.to_account)")
    println("  Rate: $(t.discount_rate)")
    println("  Maturity: $(t.maturity_date)")
    println()
end
```

## MES Interpretation

This example demonstrates how MES can model complex financial transactions with:

### 1. Category Structure
- Objects represent accounts
- Morphisms represent transactions with lambda functions for calculations
- Patterns represent transaction sequences

### 2. Time Evolution
- Transactions are timestamped
- Present values are calculated based on time to maturity
- Multiple transfers over the 6-month period

### 3. Documentation and Logging
- Each transaction is logged with full details
- Present values and discounts are tracked
- Transaction sequence is preserved

### 4. Double-Entry System
- All transactions maintain double-entry principles
- Discount accounts track value changes
- CB operations are properly recorded

## Next Steps

Check out the [Theory](../theory/categories.md) section for mathematical details about categories and patterns in MES. 