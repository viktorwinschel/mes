# Synchronization

This page demonstrates how to work with synchronization in MES.

## Basic Synchronization

```julia
using MES

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

# Run synchronization
history = simulate_synchronization(oscillators, connections, 100)
```

## Phase Locking

```julia
# Create two oscillators
osc1 = create_oscillator(1.0, 0.2)
osc2 = create_oscillator(1.0, 0.2)

# Set initial phases
set_phase!(osc1, 0.0)
set_phase!(osc2, π/4)

# Run simulation
phases = []
for t in 1:100
    update_oscillators!([osc1, osc2], [(1, 2, 0.3)])
    push!(phases, (get_phase(osc1), get_phase(osc2)))
end

# Calculate phase locking value
plv = calculate_plv(phases)
```

## Co-regulation

```julia
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
```

## Entrainment

```julia
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
``` 