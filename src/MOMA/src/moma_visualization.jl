module MOMAVisualization

using Plots
using DataFrames
using Dates
using ..MOMASimulation: MOMALandscape

# Plot balance sheet evolution for an agent
function plot_balance_sheet_evolution(landscape::MOMALandscape, agent_name::String)
    # Filter results for the agent
    agent_results = filter(row -> row.agent == agent_name, landscape.results)

    if nrow(agent_results) == 0
        return plot(title="Balance Sheet Evolution - $agent_name (No Data)",
            xlabel="Date",
            ylabel="Balance")
    end

    # Create unique dates and accounts
    dates = unique(agent_results.date)
    accounts = unique(agent_results.account)

    # Create plot
    p = plot(title="Balance Sheet Evolution - $agent_name",
        xlabel="Date",
        ylabel="Balance",
        legend=:outerright)

    # Plot each account
    for account in accounts
        account_data = filter(row -> row.account == account, agent_results)
        plot!(p, account_data.date, account_data.balance, label=account)
    end

    return p
end

# Plot transaction flow between agents
function plot_transaction_flow(landscape::MOMALandscape)
    if nrow(landscape.results) == 0
        return plot(title="Transaction Flow Over Time (No Data)",
            xlabel="Date",
            ylabel="Amount")
    end

    # Get unique dates
    dates = unique(landscape.results.date)

    # Create plot
    p = plot(title="Transaction Flow Over Time",
        xlabel="Date",
        ylabel="Amount",
        legend=:outerright)

    # Plot total debits and credits
    for date in dates
        date_data = filter(row -> row.date == date, landscape.results)
        total_debits = sum(date_data.debit)
        total_credits = sum(date_data.credit)

        plot!(p, [date], [total_debits], marker=:circle, label="Total Debits")
        plot!(p, [date], [total_credits], marker=:circle, label="Total Credits")
    end

    return p
end

# Generate summary statistics
function generate_summary_stats(landscape::MOMALandscape)
    # Calculate total transactions
    total_transactions = nrow(landscape.results)
    total_amount = sum(landscape.results.debit) + sum(landscape.results.credit)

    # Initialize DataFrames with empty arrays
    agent_stats = DataFrame(
        agent=String[],
        num_transactions=Int[],
        total_amount=Float64[]
    )

    account_stats = DataFrame(
        account=String[],
        num_transactions=Int[],
        total_amount=Float64[]
    )

    # Include all agents, even if they don't have transactions
    for agent_name in keys(landscape.agents)
        agent_data = filter(row -> row.agent == agent_name, landscape.results)
        push!(agent_stats, (
            agent_name,
            nrow(agent_data),
            nrow(agent_data) > 0 ? sum(agent_data.debit) + sum(agent_data.credit) : 0.0
        ))
    end

    # Calculate transactions by account type
    if total_transactions > 0
        for account in unique(landscape.results.account)
            account_data = filter(row -> row.account == account, landscape.results)
            push!(account_stats, (
                account,
                nrow(account_data),
                sum(account_data.debit) + sum(account_data.credit)
            ))
        end
    end

    return Dict(
        "total_transactions" => total_transactions,
        "total_amount" => total_amount,
        "agent_stats" => agent_stats,
        "account_stats" => account_stats
    )
end

# Generate final balance sheets for all agents
function generate_final_balance_sheets(landscape::MOMALandscape)
    final_balance_sheets = Dict()

    for agent_name in keys(landscape.agents)
        final_balance_sheets[agent_name] = generate_balance_sheet(landscape, agent_name)
    end

    return final_balance_sheets
end

# Print summary report
function print_summary_report(landscape::MOMALandscape)
    println("MOMA Simulation Summary Report")
    println("=============================")

    # Print summary statistics
    stats = generate_summary_stats(landscape)
    println("\nOverall Statistics:")
    println("Total Transactions: ", stats["total_transactions"])
    println("Total Amount: ", stats["total_amount"])

    println("\nTransactions by Agent:")
    println(stats["agent_stats"])

    println("\nTransactions by Account:")
    println(stats["account_stats"])

    # Print final balance sheets
    println("\nFinal Balance Sheets:")
    balance_sheets = generate_final_balance_sheets(landscape)

    for (agent_name, sheet) in balance_sheets
        println("\n$agent_name:")
        println("Assets:")
        println(sheet["assets"])
        println("Liabilities:")
        println(sheet["liabilities"])
        println("Net Worth: ", sheet["net_worth"])
    end
end

end # module MOMAVisualization