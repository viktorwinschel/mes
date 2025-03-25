"""
Synchronization and Co-regulation Examples from MES Book

These examples demonstrate:
- Neural synchronization
- Co-regulation mechanisms
- Phase locking and entrainment
"""

using MES

# Example 1: Basic neural synchronization
function example_basic_sync()
    # Create a network of oscillators
    oscillators = [
        create_oscillator(1.0, 0.1),  # frequency 1.0, coupling strength 0.1
        create_oscillator(1.1, 0.1),
        create_oscillator(0.9, 0.1)
    ]

    # Create connections
    connections = [
        (1, 2, 0.2),  # oscillator 1 to 2 with weight 0.2
        (2, 3, 0.2),
        (3, 1, 0.2)
    ]

    # Run synchronization for 100 timesteps
    history = simulate_synchronization(oscillators, connections, 100)

    return oscillators, history
end

# Example 2: Phase locking detection
function example_phase_locking()
    # Create two oscillators
    osc1 = create_oscillator(1.0, 0.2)
    osc2 = create_oscillator(1.0, 0.2)

    # Set initial phases
    set_phase!(osc1, 0.0)
    set_phase!(osc2, π / 4)

    # Run simulation
    phases = []
    for t in 1:100
        update_oscillators!([osc1, osc2], [(1, 2, 0.3)])
        push!(phases, (get_phase(osc1), get_phase(osc2)))
    end

    # Calculate phase locking value
    plv = calculate_plv(phases)

    return phases, plv
end

# Example 3: Co-regulation network
function example_co_regulation()
    # Create co-regulation network
    network = create_co_regulation_network(
        3,      # number of nodes
        0.1,    # coupling strength
        0.05    # noise level
    )

    # Set initial states
    states = Dict(
        1 => 0.8,
        2 => 0.6,
        3 => 0.4
    )

    # Run co-regulation
    history = simulate_co_regulation(network, states, 50)

    return network, history
end

# Example 4: Entrainment simulation
function example_entrainment()
    # Create driver and responder oscillators
    driver = create_oscillator(1.0, 0.3)    # strong oscillator
    responder = create_oscillator(1.2, 0.1)  # weak oscillator

    # Set up unidirectional coupling
    coupling = [(1, 2, 0.4)]  # driver -> responder

    # Run entrainment simulation
    frequencies = []
    for t in 1:200
        update_oscillators!([driver, responder], coupling)
        push!(frequencies, (get_frequency(driver), get_frequency(responder)))
    end

    # Calculate entrainment measure
    entrainment = calculate_entrainment(frequencies)

    return frequencies, entrainment
end

# Example 5: Complex synchronization patterns
function example_complex_sync()
    # Create a network with multiple frequency clusters
    oscillators = [
        # Cluster 1 (fast)
        create_oscillator(2.0, 0.1),
        create_oscillator(2.1, 0.1),
        # Cluster 2 (medium)
        create_oscillator(1.5, 0.1),
        create_oscillator(1.4, 0.1),
        # Cluster 3 (slow)
        create_oscillator(1.0, 0.1),
        create_oscillator(0.9, 0.1)
    ]

    # Create inter and intra-cluster connections
    connections = [
        # Intra-cluster (strong)
        (1, 2, 0.3),
        (3, 4, 0.3),
        (5, 6, 0.3),
        # Inter-cluster (weak)
        (2, 3, 0.1),
        (4, 5, 0.1)
    ]

    # Run simulation
    history = simulate_synchronization(oscillators, connections, 150)

    # Analyze cluster formation
    clusters = detect_clusters(history)

    return history, clusters
end

# Run all examples
function run_synchronization_examples()
    println("Running synchronization examples...")

    println("\n1. Basic Synchronization:")
    oscillators, history = example_basic_sync()
    println("Final phases: ", [get_phase(osc) for osc in oscillators])

    println("\n2. Phase Locking:")
    phases, plv = example_phase_locking()
    println("Phase Locking Value: ", plv)

    println("\n3. Co-regulation:")
    network, history = example_co_regulation()
    println("Final states: ", history[end])

    println("\n4. Entrainment:")
    frequencies, entrainment = example_entrainment()
    println("Entrainment measure: ", entrainment)

    println("\n5. Complex Synchronization:")
    history, clusters = example_complex_sync()
    println("Number of clusters: ", length(clusters))
    println("Cluster sizes: ", [length(c) for c in clusters])
end