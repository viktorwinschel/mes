"""
Advanced MOMAT Examples

This module contains advanced examples of using MES for Monetary Macro Accounting (MOMAT) modeling.
"""

using MES
using Dates

# Example 1: Complex Financial Networks
function example_complex_network()
    # Create a complex financial network
    network = create_financial_network(
        ["Bank1", "Bank2", "Bank3", "Bank4", "Bank5"],
        Dict(
            # Interbank lending
            ("Bank1", "Bank2") => 100.0,
            ("Bank2", "Bank3") => 150.0,
            ("Bank3", "Bank4") => 200.0,
            ("Bank4", "Bank5") => 250.0,
            ("Bank5", "Bank1") => 300.0,
            # Cross-border exposures
            ("Bank1", "Bank3") => 50.0,
            ("Bank2", "Bank4") => 75.0,
            ("Bank3", "Bank5") => 100.0
        )
    )

    # Create memory component for network
    memory = create_network_memory(network)

    # Simulate network evolution
    for t in 1:10
        update_network!(network, memory)
        store_network_state!(memory, network, t)
    end

    # Analyze network structure
    metrics = calculate_network_metrics(network)

    return network, memory, metrics
end

# Example 2: Systemic Risk Analysis
function example_systemic_risk(network)
    # Create a systemic risk analysis system
    system = create_systemic_risk_system(network)

    # Calculate various risk metrics
    risk_metrics = calculate_systemic_risk(system)

    # Analyze contagion potential
    contagion = analyze_contagion(system)

    # Identify systemically important banks
    sib = identify_systemic_banks(system)

    return system, risk_metrics, contagion, sib
end

# Example 3: Monetary Policy Effects
function example_monetary_policy(network)
    # Create a monetary policy simulation system
    policy_system = create_policy_system(network)

    # Define policy shocks
    shocks = [
        PolicyShock("InterestRate", -0.5, 1),  # 50bp cut at t=1
        PolicyShock("ReserveRequirement", -0.1, 5)  # 10% reduction at t=5
    ]

    # Run policy simulation
    results = simulate_policy_effects(policy_system, shocks)

    # Analyze transmission
    transmission = analyze_policy_transmission(results)

    return policy_system, results, transmission
end

# Example 4: Pattern Formation and Evolution
function example_pattern_evolution(network)
    # Create a pattern evolution system
    pattern_system = create_pattern_evolution_system(network)

    # Define initial patterns
    initial_patterns = [
        Pattern(["Bank1", "Bank2", "Bank3"], "Core"),
        Pattern(["Bank4", "Bank5"], "Periphery"),
        Pattern(["Bank1", "Bank4"], "Cross")
    ]

    # Simulate pattern evolution
    evolution = simulate_pattern_evolution(pattern_system, initial_patterns)

    # Analyze pattern dynamics
    dynamics = analyze_pattern_dynamics(evolution)

    return pattern_system, evolution, dynamics
end

# Example 5: Memory-Based Risk Assessment
function example_memory_risk(network, memory)
    # Create a memory-based risk assessment system
    risk_system = create_memory_risk_system(network, memory)

    # Define risk patterns
    risk_patterns = [
        RiskPattern("HighExposure", ["Bank1", "Bank2"], 0.8),
        RiskPattern("Concentration", ["Bank3", "Bank4"], 0.7),
        RiskPattern("Interconnectedness", ["Bank1", "Bank3", "Bank5"], 0.9)
    ]

    # Assess risks using memory
    risk_assessment = assess_risks(risk_system, risk_patterns)

    # Generate risk report
    report = generate_risk_report(risk_assessment)

    return risk_system, risk_assessment, report
end

# Run all examples
function run_advanced_examples()
    println("Running advanced MOMAT examples...")

    println("\n1. Complex Financial Network:")
    network, memory, metrics = example_complex_network()
    println("Network density: $(metrics.density)")
    println("Average path length: $(metrics.avg_path_length)")

    println("\n2. Systemic Risk Analysis:")
    system, risk_metrics, contagion, sib = example_systemic_risk(network)
    println("Network vulnerability: $(risk_metrics.vulnerability)")
    println("Contagion potential: $(contagion.potential)")
    println("Systemically important banks: $(join(sib, ", "))")

    println("\n3. Monetary Policy Effects:")
    policy_system, results, transmission = example_monetary_policy(network)
    println("Impact on lending: $(transmission.lending_impact)")
    println("Impact on network stability: $(transmission.stability_impact)")

    println("\n4. Pattern Evolution:")
    pattern_system, evolution, dynamics = example_pattern_evolution(network)
    println("Number of patterns: $(dynamics.num_patterns)")
    println("Pattern stability: $(dynamics.stability)")

    println("\n5. Memory-Based Risk Assessment:")
    risk_system, risk_assessment, report = example_memory_risk(network, memory)
    println("Overall risk level: $(report.overall_risk)")
    println("Risk patterns detected: $(length(report.patterns))")
end