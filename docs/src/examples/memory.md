# Memory Systems

This page demonstrates how to work with memory systems in MES.

## Basic Memory Operations

```julia
using MES

# Create a memory component
memory = create_memory_component(
    capacity=100,
    decay_rate=0.1
)

# Store some patterns
store_pattern!(memory, ["A", "B", "C"], 0.9)
store_pattern!(memory, ["B", "C", "D"], 0.8)

# Retrieve patterns
retrieved = retrieve_pattern(memory, ["A", "B", "C"])
```

## Memory Decay

```julia
# Create a memory with decay
memory = create_memory_component(
    capacity=5,
    decay_rate=0.2
)

# Store patterns at different times
store_pattern!(memory, ["X", "Y"], 1.0, Dates.now())
store_pattern!(memory, ["Y", "Z"], 0.9, Dates.now() - Dates.Second(10))

# Simulate decay
decay_memory!(memory)
```

## Memory Consolidation

```julia
# Create short-term and long-term memory
stm = create_memory_component(5, 0.3)  # higher decay rate
ltm = create_memory_component(20, 0.05)  # lower decay rate

# Store in STM
store_pattern!(stm, ["A", "B"], 0.9)
store_pattern!(stm, ["B", "C"], 0.85)

# Consolidate to LTM
consolidate_memory!(stm, ltm, 0.8)  # threshold 0.8
```

## Pattern Completion

```julia
# Create a completion system
system = create_completion_system(0.6)  # completion threshold

# Add known patterns
add_known_pattern!(system, ["1", "2", "3", "4"], 1.0)
add_known_pattern!(system, ["2", "3", "4", "5"], 1.0)

# Try to complete partial pattern
partial = create_pattern(["1", "2"], 0.9)
completed = complete_pattern(system, partial)
``` 