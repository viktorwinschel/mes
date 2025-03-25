"""
Memory and Pattern Formation Examples from MES Book

These examples demonstrate:
- Memory component creation and management
- Pattern formation and recognition
- Memory decay and cleanup
"""

using MES
using Dates

# Example 1: Basic memory operations
function example_basic_memory()
    # Create a memory component with capacity 10 and decay rate 0.1
    memory = create_memory_component(10, 0.1)

    # Add some patterns
    patterns = [
        create_pattern(["a", "b", "c"], 0.9),
        create_pattern(["b", "c", "d"], 0.8),
        create_pattern(["c", "d", "e"], 0.7)
    ]

    # Store patterns
    for pattern in patterns
        store_pattern!(memory, pattern)
    end

    # Retrieve and check strength
    retrieved = retrieve_pattern(memory, ["a", "b", "c"])

    return memory, retrieved
end

# Example 2: Memory decay simulation
function example_memory_decay()
    memory = create_memory_component(5, 0.2)

    # Store patterns at different times
    patterns = [
        (create_pattern(["x", "y"], 1.0), Dates.now()),
        (create_pattern(["y", "z"], 0.9), Dates.now() - Dates.Second(10)),
        (create_pattern(["z", "w"], 0.8), Dates.now() - Dates.Second(20))
    ]

    for (pattern, timestamp) in patterns
        store_pattern!(memory, pattern, timestamp)
    end

    # Simulate decay
    decay_memory!(memory)

    return memory
end

# Example 3: Pattern recognition with threshold
function example_pattern_recognition()
    # Create recognition system
    system = create_recognition_system(0.7)  # threshold 0.7

    # Add some reference patterns
    reference_patterns = [
        create_pattern(["1", "2", "3"], 1.0),
        create_pattern(["2", "3", "4"], 1.0),
        create_pattern(["3", "4", "5"], 1.0)
    ]

    for pattern in reference_patterns
        add_reference_pattern!(system, pattern)
    end

    # Test pattern for recognition
    test_pattern = create_pattern(["1", "2", "3"], 0.8)
    matches = recognize_pattern(system, test_pattern)

    return system, matches
end

# Example 4: Memory consolidation
function example_memory_consolidation()
    # Create short-term and long-term memory
    stm = create_memory_component(5, 0.3)  # higher decay rate
    ltm = create_memory_component(20, 0.05)  # lower decay rate

    # Create some patterns
    patterns = [
        create_pattern(["a", "b"], 0.9),
        create_pattern(["b", "c"], 0.85),
        create_pattern(["c", "d"], 0.8)
    ]

    # Store in STM
    for pattern in patterns
        store_pattern!(stm, pattern)
    end

    # Consolidate strong patterns to LTM
    consolidate_memory!(stm, ltm, 0.8)  # threshold 0.8

    return stm, ltm
end

# Example 5: Pattern completion
function example_pattern_completion()
    # Create completion system
    system = create_completion_system(0.6)  # completion threshold

    # Add known patterns
    known_patterns = [
        create_pattern(["1", "2", "3", "4"], 1.0),
        create_pattern(["2", "3", "4", "5"], 1.0),
        create_pattern(["3", "4", "5", "6"], 1.0)
    ]

    for pattern in known_patterns
        add_known_pattern!(system, pattern)
    end

    # Try to complete partial pattern
    partial = create_pattern(["1", "2"], 0.9)
    completed = complete_pattern(system, partial)

    return system, completed
end

# Run all examples
function run_memory_examples()
    println("Running memory examples...")

    println("\n1. Basic Memory Operations:")
    memory, retrieved = example_basic_memory()
    println("Memory size: ", length(memory.patterns))
    println("Retrieved pattern strength: ", retrieved.strength)

    println("\n2. Memory Decay:")
    decayed_memory = example_memory_decay()
    println("Patterns after decay: ", length(decayed_memory.patterns))

    println("\n3. Pattern Recognition:")
    system, matches = example_pattern_recognition()
    println("Number of matches: ", length(matches))

    println("\n4. Memory Consolidation:")
    stm, ltm = example_memory_consolidation()
    println("STM size: ", length(stm.patterns))
    println("LTM size: ", length(ltm.patterns))

    println("\n5. Pattern Completion:")
    completion_system, completed = example_pattern_completion()
    println("Completed pattern: ", completed.elements)
    println("Completion confidence: ", completed.strength)
end