# Memory Evolutive Systems Theory

This document outlines the core theoretical concepts of Memory Evolutive Systems (MES).

[MES basics](theory/mes07_formulas.md)
[MES boe](theory/mes07_boe_example.md)
[nat_acc_mes](theory/national_accounting_mes.md)

## Categories

A category $C$ consists of:
- Objects: $Ob(C)$
- Morphisms: $Hom(C)$
- Composition and identity laws

Formally, a category $C$ is defined as a collection of objects 

$Ob(C)$
and a collection of morphisms 

$Mor(C) = \{f: A \to B \mid A, B \in Ob(C)\}$

With the following axioms:
1. **Composition Closure**: $\forall f: A \to B$, $\forall g: B \to C$, $\exists g\circ f: A \to C$
2. **Associativity**: $\forall f, g, h$, $(h \circ g) \circ f = h \circ (g \circ f)$
3. **Identity**: $\forall f, A$, $\exists id_A: A \to A$, $f \circ id_A = f$, $id_A \circ f = f$

## Patterns

A pattern $P$ in a category $C$ is a diagram consisting of:
- Objects from $C$
- Morphisms between these objects
- Binding relations

Formally:
$P = (Ob(P), Mor(P))$ where:
$Ob(P) \subseteq Ob(C)$
$Mor(P) \subseteq \{f: A \to B \mid A, B \in Ob(P)\}$

## Memory

The memory component $M$ is defined as a functor:

$M: T \times E \to D$

where:
- $T$ is the time category
- $E$ is the category of events
- $D$ is the category of data

## Evolution

Evolution occurs through functors between categories at different times:

$F_t: C_t \to C_{t+1}$

with the following components:
1. **Pattern Formation**: $P_t \subseteq C_t$
2. **Binding**: $\beta: P_t \to Ob(C_{t+1})$
3. **Complex Formation**: $colim(P_t) \in Ob(C_{t+1})$

## Category Theory Basics

### Categories

In our implementation, a category is represented by the `Category` type:

```julia
struct Category{T}
    objects::Vector{T}
    morphisms::Dict{Tuple{T,T},Vector{T}}
    composition::Dict{Tuple{T,T,T},Bool}
end
```

The category must satisfy several axioms:

$Mor(C) = \{f: A \to B \mid A, B \in Ob(C)\}$
1. **Composition Closure**: For morphisms $f: A \to B$ and $g: B \to C$, there exists a composition $g\circ f: A \to C$
2. **Associativity**: For morphisms $f$, $g$, $h$, we have $(h \circ g) \circ f = h \circ (g \circ f)$
3. **Identity**: For each object $A$, there exists an identity morphism $id_A: A \to A$ such that $f \circ id_A = f$ and $id_A \circ g = g$

### Patterns and Colimits

A pattern $P$ in a category $C$ is a diagram consisting of:
- A collection of objects from $C$
- A collection of morphisms between these objects

In our implementation:

```julia
struct Pattern
    category::Category
    objects::Vector{String}
    links::Vector{Tuple{String,String}}
end
```

A colimit of a pattern $P$ is an object $C$ together with morphisms from each object in the pattern to $C$ that satisfy the universal property:
- For any other object $D$ with morphisms from the pattern objects, there exists a unique morphism $C \to D$ making all diagrams commute.

Formally:
$colim(P) = (C, \{\gamma_i: P_i \to C\}_{i \in I})$

satisfying:
$\forall D, \forall \{f_i: P_i \to D\}_{i \in I}, \exists! u: C \to D, f_i = u \circ \gamma_i$

## Memory Systems

A Memory Evolutive System extends these categorical concepts with:

### Hierarchical Categories

A hierarchical category $H$ is defined as:

$H = (C, \lambda, \beta)$ where:
- $C$ is a category
- $\lambda: Ob(C) \to \mathbb{N}$ assigns complexity levels
- $\beta: Ob(C) \times Ob(C) \to \{0,1\}$ defines bindings

In our implementation:

```julia
struct HierarchicalCategory{T}
    levels::Dict{Int,Vector{T}}
    bindings::Dict{T,Vector{T}}
    complexity::Dict{T,Int}
end
```

This structure allows us to represent:
- Objects at different complexity levels
- Bindings between levels
- Complexity measures for objects

### Memory Components

Memory components handle the storage and retrieval of information:

$M_t: C_t \to D$ with:
- Multiplicity: $\mu: Ob(C) \to \mathbb{N}$
- Decay: $\delta: Mor(C) \times \mathbb{R}_+ \to [0,1]$

In our implementation:

```julia
struct MemoryComponent{T}
    records::Vector{T}
    timestamps::Vector{DateTime}
    multiplicity::Int
    decay_rate::Float64
end
```

Key features include:
- Variable multiplicity of records
- Temporal aspects (timestamps)
- Decay of information over time

### Co-Regulators

A co-regulator $R$ is defined as:

$R = (L, \theta, \delta)$ where:
- $L: Ob(C) \to \mathbb{R}_+$ is the landscape function
- $\theta \in \mathbb{R}_+$ is the threshold
- $\delta: \mathbb{R}_+ \to [0,1]$ is the decay function

In our implementation:

```julia
struct CoRegulator{T}
    landscape::Dict{T,Float64}
    threshold::Float64
    decay_rate::Float64
end
```

They handle:
- Activation landscapes
- Thresholds for transitions
- Decay of activation levels

## Pattern Synchronization

Pattern synchronization is defined as a functor between pattern categories:

$S: P_1 \to P_2$

satisfying the commutative diagram:

$$
\begin{CD}
P_1 @>S>> P_2 \\
@VVV @VVV \\
C_1 @>F>> C_2
\end{CD}
$$

In our implementation:

```julia
struct Synchronization
    source_pattern::Pattern
    target_pattern::Pattern
end
```

This enables:
- Pattern matching across contexts
- Transfer of structure between patterns
- Coordination of complex behaviors

## Mathematical Properties

The system satisfies:

1. **Emergence**: For pattern $P$, $level(colim(P)) > \max\{level(P) \mid P \in Ob(P)\}$
2. **Stability**: $\forall t, \exists R_t$ such that $L_t(C) > \theta$ implies stability
3. **Adaptability**: $M_{t+1} = F_t \circ M_t + \Delta_t$
4. **Hierarchy**: $\forall C \in Ob(C), level(C) = 1 + \max\{level(B) \mid \exists f: B \to C\}$

These properties make MES suitable for modeling complex systems that:
- Develop hierarchical structures
- Learn from experience
- Adapt to changing conditions
- Maintain stability while evolving

## Applications

### National Accounting

For national accounting applications, we define:

$E$ = category of economic objects
$F: E \to Set$ = economic measurement functor
$\eta: F \Rightarrow G$ = natural transformations for price changes

The economic category satisfies:

$$
\begin{CD}
E_t @>F_t>> E_{t+1} \\
@V\pi_tVV @VV\pi_{t+1}V \\
\mathbb{R} @>>\phi_t> \mathbb{R}
\end{CD}
$$

where $\pi_t$ represents prices at time $t$ and $\phi_t$ represents the price transformation.

For a detailed discussion of how these categorical structures are applied to national accounting, see [National Accounting with Categorical Structures](theory/national_accounting.md). This section covers:

1. Economic objects and morphisms
2. Category construction for national accounting
3. Functors and natural transformations
4. Patterns and colimits in economic systems
5. Mathematical properties of the economic categories 