using Test
using MES
using DataFrames

@testset "Simple Economy Parameters Tests" begin
    # Define economic parameters
    params = (
        # Initial capital
        initial_capital=1000.0,
        # Production parameters
        labor_cost=100.0,
        good_price=80.0,
        # Consumption parameters
        household_consumption=80.0,
        # Time parameters
        period=1
    )

    # Create a simple economy with three core agents: company, household, and bank
    company = Agent("COMPANY", "COMPANY", ["BANK", "GOOD"])
    household = Agent("HOUSEHOLD", "HOUSEHOLD", ["BANK", "LABOR", "GOOD"])
    bank = Agent("BANK", "BANK", ["COMPANY", "HOUSEHOLD"])

    # Create accounts for each agent with proper double-entry bookkeeping
    # Company accounts
    company_bank = Account("COMPANY_BANK", "COMPANY", "BANK", params.initial_capital)
    company_good = Account("COMPANY_GOOD", "COMPANY", "GOOD", 0.0)

    # Household accounts
    household_bank = Account("HOUSEHOLD_BANK", "HOUSEHOLD", "BANK", params.household_consumption)
    household_labor = Account("HOUSEHOLD_LABOR", "HOUSEHOLD", "LABOR", params.labor_cost)
    household_good = Account("HOUSEHOLD_GOOD", "HOUSEHOLD", "GOOD", 0.0)

    # Bank accounts
    bank_company = Account("BANK_COMPANY", "BANK", "COMPANY", -params.initial_capital)
    bank_household = Account("BANK_HOUSEHOLD", "BANK", "HOUSEHOLD", -params.household_consumption)

    # Create flows for transactions
    wage_payment = Flow("WAGE_PAYMENT", "PAYMENT", "COMPANY", "HOUSEHOLD", params.labor_cost)
    good_purchase = Flow("GOOD_PURCHASE", "PURCHASE", "HOUSEHOLD", "COMPANY", params.good_price)

    # Create transactions with proper double-entry
    transactions = [
        # Wage payment transaction
        Transaction("wage_payment", company_bank, household_bank, params.labor_cost, "PAYMENT"),
        Transaction("wage_payment_labor", household_labor, company_good, params.labor_cost, "PAYMENT"),

        # Good purchase transaction
        Transaction("good_purchase", household_bank, company_bank, params.good_price, "PURCHASE"),
        Transaction("good_purchase_good", company_good, household_good, params.good_price, "PURCHASE")
    ]

    # Create a financial category with initial balances
    financial_cat = create_financial_category(
        DataFrame(
            Dict(
                # Company accounts
                "COMPANY_BANK" => [params.initial_capital],
                "COMPANY_GOOD" => [0.0],

                # Household accounts
                "HOUSEHOLD_BANK" => [params.household_consumption],
                "HOUSEHOLD_LABOR" => [params.labor_cost],
                "HOUSEHOLD_GOOD" => [0.0],

                # Bank accounts
                "BANK_COMPANY" => [-params.initial_capital],
                "BANK_HOUSEHOLD" => [-params.household_consumption],

                # Flow values
                "FLOW_PAYMENT_WAGE_PAYMENT" => [params.labor_cost],
                "FLOW_PURCHASE_GOOD_PURCHASE" => [params.good_price]
            )
        ),
        params.period
    )

    # Add morphisms to the category
    for trans in transactions
        add_morphism!(financial_cat, trans)
    end

    # Add identity morphisms for each object
    objects = [company, household, bank,
        company_bank, company_good,
        household_bank, household_labor, household_good,
        bank_company, bank_household,
        wage_payment, good_purchase]

    for obj in objects
        id_morphism = Transaction("id_$(obj.name)", obj, obj, 0.0, "IDENTITY")
        add_morphism!(financial_cat, id_morphism)
        financial_cat.identity[obj] = id_morphism
    end

    # Add simple objects for pattern creation
    simple_objects = [
        SimpleObject("COMPANY_BANK"),
        SimpleObject("HOUSEHOLD_BANK"),
        SimpleObject("BANK_COMPANY")
    ]

    for obj in simple_objects
        push!(financial_cat.objects, obj)
        id_morphism = SimpleMorphism("id_$(obj.name)", obj, obj)
        add_morphism!(financial_cat, id_morphism)
        financial_cat.identity[obj] = id_morphism
    end

    @testset "Parameter Definitions" begin
        @test params.initial_capital > 0
        @test params.labor_cost > 0
        @test params.good_price > 0
        @test params.household_consumption > 0
    end

    @testset "Account Balances" begin
        # Company accounts
        @test company_bank.balance == params.initial_capital
        @test company_good.balance == 0.0

        # Household accounts
        @test household_bank.balance == params.household_consumption
        @test household_labor.balance == params.labor_cost
        @test household_good.balance == 0.0

        # Bank accounts
        @test bank_company.balance == -params.initial_capital
        @test bank_household.balance == -params.household_consumption
    end

    @testset "Transaction Values" begin
        @test wage_payment.value == params.labor_cost
        @test good_purchase.value == params.good_price
    end

    @testset "Conservation Laws" begin
        conservation = verify_conservation_laws(financial_cat)
        @test conservation.bank_balance
    end

    @testset "Category Properties" begin
        @test verify_composition_closure(financial_cat)
        @test verify_identity_existence(financial_cat)
        @test verify_associativity(financial_cat)
        @test verify_identity_laws(financial_cat)
    end
end