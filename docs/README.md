# DESSEM2Julia Documentation Hub

**Version**: 0.1.0  
**Last Updated**: October 19, 2025

Welcome to the DESSEM2Julia documentation! This project provides Julia parsers and tools for working with DESSEM (Daily Operation Scheduling Program) input files used in Brazilian power system operations.

---

> **🗺️ NEW: [Complete Documentation Index](INDEX.md)** - Wiki-style navigation for all documentation

---

## 📚 Quick Navigation

### 🎯 **Getting Started**
- [Quick Start Guide](planning/QUICK_START_GUIDE.md) - Get up and running in minutes
- [Project Context](planning/PROJECT_CONTEXT.md) - Understanding the project's goals and scope
- [Repository Structure](REPOSITORY_STRUCTURE.md) - Navigate the codebase

### 📖 **Core Documentation**

#### File Formats & Specifications
- **[File Formats Overview](file_formats.md)** - Complete list of DESSEM files and parser status
- **[Complete DESSEM Specifications](dessem-complete-specs.md)** - Official format specifications
- **[Format Notes](FORMAT_NOTES.md)** - Implementation notes and observations
- **[Type System](type_system.md)** - Julia type definitions and data structures

#### Architecture & Design
- **[Architecture Overview](architecture.md)** - System design and components
- **[Entity Relationships](ENTITY_RELATIONSHIPS.md)** - How DESSEM entities relate to each other
- **[Reorganization Summary](REORGANIZATION_SUMMARY.md)** - Project structure evolution

---

## 🔍 **Parser Documentation**

### Implemented Parsers

#### HIDR.DAT - Hydroelectric Registry
- **[HIDR Quick Reference](HIDR_QUICK_REFERENCE.md)** - Common queries and usage patterns
- **[HIDR Entity Diagram](HIDR_ENTITY_DIAGRAM.md)** - Complete entity relationships
- **[HIDR Binary Implementation](HIDR_BINARY_COMPLETE.md)** - Binary format details (792 bytes/plant)
- **[Entity Relationships § HIDR](ENTITY_RELATIONSHIPS.md#2-hydroelectric-plant-relationships)** - Integration with other files

**Key Features**:
- ✅ Binary format (792 bytes/plant, 111 fields)
- ✅ Text format (7 record types: CADUSIH, USITVIAG, POLCOT, POLARE, POLJUS, COEFEVA, CADCONJ)
- ✅ Auto-detection (binary vs text)
- ✅ Cascade topology (DAG structure)

#### ENTDADOS.XXX - System Configuration
- **[Parser Implementation](parsers/OPERUT_IMPLEMENTATION.md)** - Technical details
- **[Entity Relationships § Subsystems](ENTITY_RELATIONSHIPS.md#1-geographical-electrical-hierarchy)** - Hierarchical structure

**Status**: ✅ Complete (8 new record types added)

#### DADVAZ.XXX - Inflow Data
- **[Parser Status](file_formats.md#dadvazdathm)** - Current implementation
- **[Entity Relationships § Inflow](ENTITY_RELATIONSHIPS.md#detailed-relationships)** - Data connections

**Status**: ✅ Complete

#### DESSEM.ARQ - Main Configuration
- **[Parser Status](file_formats.md#dessemarq)** - Implementation details
- **[Format Specifications](dessem-complete-specs.md#dessemarq)** - File structure

**Status**: ✅ Complete

#### OPERUT.XXX - Thermal Operations
- **[Implementation Guide](parsers/OPERUT_IMPLEMENTATION.md)** - Complete technical documentation
- **[Entity Relationships § Thermal](ENTITY_RELATIONSHIPS.md#3-thermal-plant-relationships)** - Thermal plant structure

**Status**: ✅ Complete

#### OPERUH.XXX - Hydro Operations
- **[Parser Status](file_formats.md#operuhxxx)** - Current implementation
- **[Test Comparison](parsers/idessem_comparison.md)** - Validation against IDESSEM

**Status**: ✅ Complete

#### TERMDAT.XXX - Thermal Registry
- **[Parser Status](file_formats.md#termdatxxx)** - Implementation details
- **[Entity Relationships § Thermal Units](ENTITY_RELATIONSHIPS.md#5-hydro-unit-hierarchy)** - Unit hierarchy

**Status**: ✅ Complete

### Binary File Parsers
- **[Binary Files Overview](parsers/BINARY_FILES.md)** - Binary format documentation
- **[HIDR Binary Format](HIDR_BINARY_COMPLETE.md)** - 792-byte structure details

---

## 🎓 **Tutorials & Examples**

### Code Examples
Located in `examples/` directory:
- **[Hydro Tree Visualization](../examples/hydro_tree_example.jl)** - Advanced cascade analysis
- **[Simple Hydro Tree](../examples/simple_hydro_tree.jl)** - Clean cascade display
- **[Parse Sample Case](../examples/parse_sample_case.jl)** - Basic parsing example
- **[ONS Compatibility](../examples/verify_ons_compatibility.jl)** - Validation scripts

### Query Patterns
- **[HIDR Queries](ENTITY_RELATIONSHIPS.md#hidrdat-queries)** - Hydroelectric data queries
- **[Cross-File Queries](ENTITY_RELATIONSHIPS.md#query-examples)** - Multi-file data integration

### Sample Data
Located in `docs/Sample/` directory:
- **[ONS Sample](Sample/ONS_VALIDATION.md)** - Official ONS data (DS_ONS_102025_RV2D11)
- **[CCEE Samples](Sample/SAMPLE_VALIDATION.md)** - CCEE market data (RV0, RV1)
- **[Sample Validation](Sample/SAMPLE_VALIDATION.md)** - Test results and validation

---

## 🔬 **Technical References**

### Compatibility & Validation
- **[ONS Compatibility Summary](planning/ONS_COMPATIBILITY_SUMMARY.md)** - Compatibility status with official ONS data
- **[IDESSEM Comparison](parsers/idessem_comparison.md)** - Comparison with Python implementation

### Implementation Details
- **[Parser Registry](../src/parser/registry.jl)** - Parser registration system
- **[Common Parser Utilities](../src/parser/common.jl)** - Shared parsing functions
- **[Type Definitions](../src/types.jl)** - All data structures

### Testing
- **Test Files**: `test/` directory
  - Core types tests
  - Individual parser tests (HIDR, ENTDADOS, DADVAZ, etc.)
  - ONS integration tests
  - Parser common utilities tests

---

## 📋 **Task Management**

### Current Status
- **[Task List](planning/TASKS.md)** - What's done, what's next
- **[Project Context](planning/PROJECT_CONTEXT.md)** - Current priorities

### Session Notes
Located in `docs/sessions/` directory:
- [Session 5 Summary](sessions/session5_summary.md)
- [Session 6 Summary](sessions/session6_summary.md)
- [Session 7 Summary](sessions/session7_summary.md)
- [Session 8 Summary](sessions/session8_summary.md)
- [HIDR Documentation Update](sessions/HIDR_DOCUMENTATION_UPDATE.md)
- [Session Summary](sessions/SESSION_SUMMARY.md)

---

## 🌳 **Data Model**

### Entity Relationships

The DESSEM file system forms a distributed relational database. Key relationships:

```
SUBSYSTEM (1) ──► (*) HYDRO_PLANT ──► (*) HYDRO_UNIT_SET ──► (*) HYDRO_UNIT
                      │
                      └──► (*) INFLOW_DATA
                      └──► (*) OPERATIONAL_CONSTRAINTS

SUBSYSTEM (1) ──► (*) THERMAL_PLANT ──► (*) THERMAL_UNIT
                      │
                      └──► (*) OPERATIONAL_DATA
```

**Detailed Documentation**:
- [Entity Relationships](ENTITY_RELATIONSHIPS.md) - Complete ER model
- [HIDR Entity Diagram](HIDR_ENTITY_DIAGRAM.md) - Hydroelectric specific
- [Type System](type_system.md) - Julia struct definitions

### Cascade Topology

Hydroelectric plants form a directed acyclic graph (DAG) representing water flow:

```
Upstream Plant (root)
    └─► downstream_plant → Intermediate Plant
                             └─► downstream_plant → Terminal Plant
```

**Real-World Example**: Paranapanema River (11 plants, 923 MW)
```
A.A. LAYDNER → PIRAJU → PARANAPANEMA → CHAVANTES → OURINHOS → 
L.N. GARCEZ → CANOAS II → CANOAS I → CAPIVARA → TAQUARUCU → ROSANA
```

**Learn More**: [HIDR Entity Diagram § Cascade Topology](HIDR_ENTITY_DIAGRAM.md#cascade-topology-self-referencing-fk)

---

## 📊 **Statistics & Metrics**

### Parser Implementation Status

| File Type | Status | Records/Types | Binary Support |
|-----------|--------|---------------|----------------|
| HIDR.DAT | ✅ Complete | 7 types | ✅ Yes (792 bytes) |
| ENTDADOS.XXX | ✅ Complete | 8 types | ❌ No |
| DADVAZ.XXX | ✅ Complete | 1 type | ❌ No |
| DESSEM.ARQ | ✅ Complete | Multiple | ❌ No |
| OPERUT.XXX | ✅ Complete | Multiple | ❌ No |
| OPERUH.XXX | ✅ Complete | Multiple | ❌ No |
| TERMDAT.XXX | ✅ Complete | 2 types | ❌ No |

**Total Parsers**: 7 complete / ~40 files (~18% coverage)

### Test Coverage

- **ONS Sample**: DS_ONS_102025_RV2D11
  - 185 hydroelectric plants parsed
  - 24,218 MW total capacity
  - 4 subsystems (SE, S, NE, N)
  - 109 cascade starting points

- **CCEE Samples**: DS_CCEE_102025
  - RV0D28: Validated
  - RV1D04: Validated

**Validation**: [Sample Validation](Sample/SAMPLE_VALIDATION.md)

---

## 🔧 **Development**

### Setup & Installation
See [Quick Start Guide](planning/QUICK_START_GUIDE.md)

### Project Structure
```
DESSEM2Julia/
├── src/              # Source code
│   ├── parser/       # File parsers
│   ├── models/       # Data models
│   └── types.jl      # Type definitions
├── test/             # Test suite
├── examples/         # Usage examples
└── docs/             # Documentation (you are here!)
    ├── parsers/      # Parser-specific docs
    ├── planning/     # Project planning
    ├── sessions/     # Session notes
    └── Sample/       # Sample data & validation
```

**Details**: [Repository Structure](REPOSITORY_STRUCTURE.md)

### Contributing

When adding a new parser:
1. Read [Architecture Overview](architecture.md)
2. Study [Entity Relationships](ENTITY_RELATIONSHIPS.md)
3. Follow [Type System](type_system.md) conventions
4. Add tests following existing patterns
5. Update [File Formats](file_formats.md) status
6. Document in appropriate section

---

## 🔗 **Quick Links**

### Most Common Tasks

**Parse HIDR.DAT file**:
```julia
using DESSEM2Julia
hidr_data = parse_hidr("hidr.dat")  # Auto-detects binary/text
```
→ [HIDR Quick Reference](HIDR_QUICK_REFERENCE.md)

**Parse ENTDADOS file**:
```julia
entdados = parse_entdados("entdados.dat")
```
→ [Entity Relationships](ENTITY_RELATIONSHIPS.md)

**Build cascade tree**:
```julia
# See examples/hydro_tree_example.jl
```
→ [Hydro Tree Example](../examples/hydro_tree_example.jl)

**Validate against ONS data**:
```julia
# See examples/verify_ons_compatibility.jl
```
→ [ONS Compatibility](planning/ONS_COMPATIBILITY_SUMMARY.md)

### External Resources

- **IDESSEM** (Python reference): https://github.com/rjmalves/idessem
- **ONS** (Brazilian Grid Operator): https://www.ons.org.br
- **CCEE** (Energy Trading Chamber): https://www.ccee.org.br

---

## 📝 **Document Index**

### By Category

<details>
<summary><strong>Planning & Project Management</strong></summary>

- [Project Context](planning/PROJECT_CONTEXT.md)
- [Quick Start Guide](planning/QUICK_START_GUIDE.md)
- [Tasks](planning/TASKS.md)
- [ONS Compatibility Summary](planning/ONS_COMPATIBILITY_SUMMARY.md)

</details>

<details>
<summary><strong>Specifications & Formats</strong></summary>

- [File Formats Overview](file_formats.md)
- [Complete DESSEM Specifications](dessem-complete-specs.md)
- [Format Notes](FORMAT_NOTES.md)
- [Binary Files](parsers/BINARY_FILES.md)

</details>

<details>
<summary><strong>Architecture & Design</strong></summary>

- [Architecture Overview](architecture.md)
- [Type System](type_system.md)
- [Repository Structure](REPOSITORY_STRUCTURE.md)
- [Reorganization Summary](REORGANIZATION_SUMMARY.md)

</details>

<details>
<summary><strong>Entity Relationships</strong></summary>

- [Entity Relationships (Main)](ENTITY_RELATIONSHIPS.md)
- [HIDR Entity Diagram](HIDR_ENTITY_DIAGRAM.md)
- [HIDR Quick Reference](HIDR_QUICK_REFERENCE.md)

</details>

<details>
<summary><strong>Parser Documentation</strong></summary>

- [HIDR Binary Complete](HIDR_BINARY_COMPLETE.md)
- [OPERUT Implementation](parsers/OPERUT_IMPLEMENTATION.md)
- [IDESSEM Comparison](parsers/idessem_comparison.md)

</details>

<details>
<summary><strong>Samples & Validation</strong></summary>

- [ONS Validation](Sample/ONS_VALIDATION.md)
- [Sample Validation](Sample/SAMPLE_VALIDATION.md)

</details>

<details>
<summary><strong>Session Notes</strong></summary>

- [Session 5](sessions/session5_summary.md)
- [Session 6](sessions/session6_summary.md)
- [Session 7](sessions/session7_summary.md)
- [Session 8](sessions/session8_summary.md)
- [HIDR Documentation Update](sessions/HIDR_DOCUMENTATION_UPDATE.md)
- [Session Summary](sessions/SESSION_SUMMARY.md)

</details>

---

## 🎯 **Next Steps**

1. **New Users**: Start with [Quick Start Guide](planning/QUICK_START_GUIDE.md)
2. **Developers**: Read [Architecture](architecture.md) and [Entity Relationships](ENTITY_RELATIONSHIPS.md)
3. **Contributors**: Check [Tasks](planning/TASKS.md) for what's needed
4. **Researchers**: Explore [Sample Data](Sample/) and [Examples](../examples/)

---

## 📞 **Need Help?**

- **Can't find what you need?** Check the [Document Index](#-document-index) above
- **Parser not working?** See [ONS Compatibility](planning/ONS_COMPATIBILITY_SUMMARY.md)
- **Understanding data structure?** Read [Entity Relationships](ENTITY_RELATIONSHIPS.md)
- **Want examples?** Look in `examples/` directory or [Query Patterns](ENTITY_RELATIONSHIPS.md#query-examples)

---

<div align="center">

**Happy Parsing! 🚀**

[Back to Top](#dessem2julia-documentation-hub) | [GitHub Repository](https://github.com/yourusername/DESSEM2Julia)

</div>
