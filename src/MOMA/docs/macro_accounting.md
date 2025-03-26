# Macro Accounting in MOMA

## Overview

Macro accounting represents the system-wide view of financial relationships between agents. Unlike micro accounting, which tracks all debits and credits within each agent's books, macro accounting focuses solely on claims between agents.

## Key Principles

1. **No Net Debt**
   - At the macro level, every debt has exactly one debtor and one creditor
   - Claims between agents must net to zero
   - Example:
     ```
     Bank A's claim on Bank B = Bank B's liability to Bank A
     ```

2. **Internal vs External Accounts**
   - Internal accounts (like "Bicycle") don't appear in macro accounting
   - Only inter-agent claims (like loans, deposits) matter at macro level
   - Example:
     ```
     Micro level (Bank A's books):
     DR Bicycle        | 100
     CR Cash          | 100

     Macro level:
     (No effect - internal transaction)
     ```

3. **Claim Transfer Without Net Change**
   - When claims are transferred between agents, total claims remain constant
   - Only the holder of the claim changes
   - Example:
     ```
     Initial: S has claim on B
     After transfer: Bank has claim on B, S has deposit at Bank
     Total claims = 100 (unchanged)
     ```

## Implementation

### Account Pairs
We track corresponding debtor-creditor pairs:
```julia
debt_pairs = [
    ("Deposits at Banks", "Deposits from Banks"),
    ("Loans to Banks", "Loans from CB"),
    ("Receivable from BOE", "Liability from BOE"),
    # ...
]
```

### Invariance Checks
1. **Micro Invariance** (within each agent):
   ```julia
   total_debits = sum(account.debit for account in agent.accounts)
   total_credits = sum(account.credit for account in agent.accounts)
   @test total_debits ≈ total_credits
   ```

2. **Macro Invariance** (between agents):
   ```julia
   for (claim, liability) in debt_pairs
       total = sum(claim_positions) + sum(liability_positions)
       @test total ≈ 0
   end
   ```

## Examples

### 1. Money Creation
```
Micro level (CB's books):
DR Paper Money              | 1000
CR Paper Money in Circulation| 1000

Macro level:
No net debt created (internal to CB)
```

### 2. Loan Creation
```
Micro level (CB's books):
DR Loans to Banks    | 200
CR Deposits from Banks| 200

Micro level (Bank's books):
DR CB Reserve       | 200
CR Loans from CB    | 200

Macro level:
CB's claim (200) = Bank's liability (200)
```

### 3. BOE Chain
```
Initial:
S's claim on B (100) = B's liability to S (100)

After bank transfer:
Bank's claim on B (100) = B's liability (100)
S's deposit at Bank (100) = Bank's liability to S (100)

Total claims remain = 100
```

## Testing

We test macro accounting properties:
1. Debtor-creditor pairs net to zero
2. Claim transfers preserve total claims
3. Settlement cancels offsetting claims

Example test:
```julia
@test "BOE Chain - Claim Transfer Without Net Change" begin
    # Initial state
    s_claim = get_account_balance(S, "Receivable from BOE")
    b_liability = get_account_balance(B, "Liability from BOE")
    @test s_claim ≈ b_liability

    # After transfer
    banks_claim = get_account_balance(Banks, "Receivable from BOE")
    s_deposit = get_account_balance(S, "Deposits at Banks")
    @test banks_claim ≈ s_deposit
    @test banks_claim ≈ b_liability  # Total claims unchanged
end
```

## Visualization

The macro view can be visualized as a network:
- Nodes = Agents
- Edges = Claims (direction = creditor → debtor)
- Edge weights = Claim amounts

This shows how claims connect agents while netting to zero system-wide. 