# Financial Events

MOMA models various types of financial events using categorical diagrams. Each event represents double-entry bookings between accounts.

## Money Creation

The money creation event represents the process by which central banks create new money:

For Central Bank (CB):
- Debit: Paper Money (asset)
- Credit: Paper Money in Circulation (liability)

```julia
date = Date("2025-01-15")
diagram = create_money_creation_diagram(1000.0, date)
```

## Loans

The loans event represents the creation of loans and deposits between the central bank and commercial banks:

For Central Bank (CB):
- Debit: Loans to Banks (asset)
- Debit: Loans to Bankb (asset)
- Credit: Deposits from Banks (liability)
- Credit: Deposits from Bankb (liability)

For Banks:
- Debit: CB Reserve (asset)
- Credit: Loans from CB (liability)

For Bankb:
- Debit: CB Reserve (asset)
- Credit: Loans from CB (liability)

```julia
diagram = create_loans_diagram(200.0, date)
```

## Bicycle Purchase

The bicycle purchase event represents a goods transaction:

For Buyer (B):
- Debit: Bicycle (asset)
- Credit: Liability General (liability)

For Seller (S):
- Debit: Receivable General (asset)
- Credit: Bicycle (asset)

```julia
diagram = create_bicycle_purchase_diagram(100.0, date)
```

## Bill of Exchange (BOE)

### BOE Creation

The BOE creation event transforms general liabilities into formal bills of exchange:

For Seller (S):
- Debit: Receivable from BOE (asset)
- Credit: Liability from BOE (liability)

For Buyer (B):
- Debit: Liability General (liability)
- Credit: Liability from BOE (liability)

```julia
diagram = create_boe_creation_diagram(100.0, date)
```

### BOE Bank Transfer - Banks and S

The first BOE transfer event represents the bank accepting the BOE from the seller:

For Banks (S's bank):
- Debit: Receivable from BOE (asset)
- Credit: Deposits from S (liability)

For Seller (S):
- Debit: Deposits at Banks (asset)
- Credit: Receivable from BOE (asset)

### BOE Bank Transfer - Bankb and Banks

The second BOE transfer event represents the interbank transfer:

For Bankb (B's bank):
- Debit: Receivable from BOE (asset)
- Credit: Deposits from Banks (liability)

For Banks:
- Debit: Deposits at Bankb (asset)
- Credit: Receivable from BOE (asset)

## Final Settlement

The settlement event represents the final clearing between banks:

For Banks:
- Debit: Deposits at Bankb (asset)
- Credit: CB Reserve (asset)

For Bankb:
- Debit: CB Reserve (asset)
- Credit: Deposits from Banks (liability)

## Full Event Sequence

MOMA models a complete transaction cycle through seven events:

1. Money Creation: CB creates initial money supply
2. Loans: CB creates loans and deposits for banks
3. Bicycle Purchase: B buys bicycle from S
4. BOE Creation: S and B formalize the debt as a bill of exchange
5. BOE Bank Transfer (Banks-S): S's bank accepts the BOE
6. BOE Bank Transfer (Bankb-Banks): Interbank BOE transfer
7. Final Settlement: Banks clear their positions

Each event:
- Maintains double-entry bookkeeping principles
- Preserves accounting identities
- Can be analyzed through categorical structures

## Verification

For any financial event, MOMA ensures:

1. **Double-Entry Consistency**:
   - Each transaction has equal debits and credits
   - Account types (asset/liability) determine balance changes

2. **Balance Sheet Effects**:
   - Assets = Liabilities + Net Worth
   - All flows preserve accounting identities

3. **Multi-level Analysis**:
   - Micro level: Individual account changes
   - Macro level: Aggregate balance sheet effects

## See Also

- [Category Theory](category.md) for mathematical foundations
- [Functorial Analysis](functors.md) for level mappings
- [API Reference](../api/events.md) for function details 