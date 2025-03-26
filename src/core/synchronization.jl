"""
    Synchronization

A type representing a synchronization between two patterns.

# Fields
- `source_pattern::Pattern`: The source pattern
- `target_pattern::Pattern`: The target pattern
"""
struct Synchronization
    source_pattern::Pattern
    target_pattern::Pattern
end

"""
    verify_synchronization(sync::Synchronization)

Verify that a synchronization is valid.

# Arguments
- `sync::Synchronization`: The synchronization to verify

# Returns
A boolean indicating whether the synchronization is valid.
"""
function verify_synchronization(sync::Synchronization)
    return sync.source_pattern !== nothing && sync.target_pattern !== nothing
end