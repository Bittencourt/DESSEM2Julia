# DESSEM2Julia Documentation Index

**Welcome to the DESSEM2Julia documentation!** This is your central navigation hub for all project documentation.

---

## 📚 Quick Navigation

| Section | Description | Best For |
|---------|-------------|----------|
| [🚀 Getting Started](#-getting-started) | New users, setup guides | First-time users |
| [🏗️ Architecture](#%EF%B8%8F-architecture--design) | Project structure, design decisions | Understanding codebase |
| [📖 File Formats](#-file-formats) | DESSEM input file specifications | Parser developers |
| [🔗 Data Relationships](#-data-relationships) | Entity relationships, foreign keys | Data modeling |
| [⚙️ Parser Implementation](#%EF%B8%8F-parser-implementation) | Parser guides, implementation details | Contributors |
| [💻 API Reference](#-api-reference) | Types, functions, usage examples | Developers |
| [📊 Examples](#-examples) | Working code examples | Quick implementation |
| [📝 Development Logs](#-development-logs) | Session summaries, progress tracking | Project history |

---

## 🚀 Getting Started

Perfect for new users who want to understand and use DESSEM2Julia.

### Quick Start
- **[Quick Start Guide](planning/QUICK_START_GUIDE.md)** 📘
  - Installation instructions
  - First steps with the library
  - Basic usage examples
  - Common workflows

### Project Overview
- **[Project Context](planning/PROJECT_CONTEXT.md)** 🎯
  - Project goals and motivation
  - Scope and features
  - Design philosophy
  - Development roadmap

- **[Repository Structure](REPOSITORY_STRUCTURE.md)** 📁
  - Directory organization
  - File naming conventions
  - Module structure
  - Testing organization

---

## 🏗️ Architecture & Design

Understanding how DESSEM2Julia is structured and why.

### Core Architecture
- **[Architecture Overview](architecture.md)** 🏛️
  - System design principles
  - Module organization
  - Data flow architecture
  - Extension points

### Type System
- **[Type System Documentation](type_system.md)** 🔷
  - Core type definitions
  - Type hierarchies
  - Struct relationships
  - Design patterns
  - See also: [Entity Relationships](#-data-relationships)

---

## 📖 File Formats

Complete specifications for DESSEM input file formats.

### Format Overview
- **[File Formats Summary](file_formats.md)** 📋
  - All DESSEM file types
  - Parser implementation status
  - Format types (text, binary, fixed-width)
  - Quick reference table

### Detailed Specifications
- **[DESSEM Complete Specs](dessem-complete-specs.md)** 📚
  - Complete file format specifications
  - Field definitions
  - Data types
  - Validation rules

- **[Format Notes](FORMAT_NOTES.md)** 📝
  - Implementation notes
  - Format quirks and edge cases
  - Parsing challenges
  - Solutions and workarounds

### Binary File Formats
- **[Binary Files Overview](parsers/BINARY_FILES.md)** 🔢
  - Binary format structures
  - Byte-level specifications
  - Endianness considerations
  - Parsing strategies

---

## 🔗 Data Relationships

Understanding how DESSEM data entities relate to each other.

### Core Relationships
- **[Entity Relationships](ENTITY_RELATIONSHIPS.md)** 🔗 **[ESSENTIAL READ]**
  - Complete relationship model
  - Foreign key mappings
  - Cascade topology
  - Cross-file references
  - Query examples (15+ patterns)
  - Real-world examples (ONS data)
  
  **Key Sections**:
  - Subsystem relationships
  - Hydroelectric plant relationships (HIDR.DAT)
  - Thermal plant relationships
  - Cascade topology (river basin networks)
  - Hydro unit hierarchy (3 levels)
  - Temporal relationships
  - Spatial relationships (network topology)

### HIDR.DAT Relationships (Detailed)
- **[HIDR Entity Diagram](HIDR_ENTITY_DIAGRAM.md)** 📊
  - Complete visual diagrams
  - 7 entity types (CADUSIH, USITVIAG, POLCOT, etc.)
  - Cascade topology visualization
  - Cross-file foreign keys
  - Data flow diagrams

---

## ⚙️ Parser Implementation

Guides for implementing and using file parsers.

### HIDR.DAT Parser (Complete ✅)
The HIDR.DAT parser is fully implemented with both binary and text format support.

- **[HIDR Quick Reference](HIDR_QUICK_REFERENCE.md)** 🚀 **[START HERE]**
  - Basic usage examples
  - Format comparison (binary vs text)
  - Common query patterns (8 examples)
  - Real-world ONS statistics
  - Field descriptions
  
- **[HIDR Binary Implementation](HIDR_BINARY_COMPLETE.md)** ⚙️ **[TECHNICAL DETAILS]**
  - Binary format specification (792 bytes/plant)
  - 111 fields documented
  - Implementation guide
  - IDESSEM comparison
  - Test results from ONS sample
  - Performance notes
  
- **[HIDR Entity Relationships](HIDR_ENTITY_DIAGRAM.md)** 🔗
  - See [Data Relationships](#-data-relationships) section above

**Key Features**:
- ✅ Binary format (792 bytes/plant, 111 fields)
- ✅ Text format (7 record types)
- ✅ Auto-detection (single `parse_hidr()` function)
- ✅ Tested with ONS samples (185 plants, 24,218 MW)
- ✅ Complete cascade topology support

### OPERUT Parser
- **[OPERUT Implementation](parsers/OPERUT_IMPLEMENTATION.md)** 🔧
  - Thermal plant operational constraints
  - Record types and structures
  - Implementation status
  - Usage examples

### Parser Comparisons
- **[IDESSEM Comparison](parsers/idessem_comparison.md)** 🔄
  - Comparison with IDESSEM (Python reference)
  - Design differences
  - Compatibility notes
  - Migration guide

### General Parser Guidelines
- **[Format Notes](FORMAT_NOTES.md)** 💡
  - Common parsing patterns
  - Error handling strategies
  - Validation approaches
  - Testing best practices

---

## 💻 API Reference

How to use DESSEM2Julia in your code.

### Core API
- **[Type System](type_system.md)** 🔷
  - All struct definitions
  - Type hierarchies
  - Field descriptions
  - Usage examples

### Parser Functions
See individual parser documentation:
- [HIDR Quick Reference](HIDR_QUICK_REFERENCE.md) - `parse_hidr()`
- [File Formats](file_formats.md) - All parser functions
- [Entity Relationships](ENTITY_RELATIONSHIPS.md) - Query patterns

### Usage Patterns
- **[Entity Relationships - Query Examples](ENTITY_RELATIONSHIPS.md#query-examples)** 🔍
  - HIDR.DAT queries (parse, filter, cascade analysis)
  - Subsystem filtering
  - Cascade traversal
  - Polynomial evaluation
  - Cross-file joins

---

## 📊 Examples

Working code examples for common tasks.

### Location
All examples are in the `examples/` directory at the project root.

### Available Examples

#### Hydroelectric Analysis
- **`examples/simple_hydro_tree.jl`** 🌳 **[RECOMMENDED]**
  - Clean cascade visualization
  - Pre-selected interesting cascades
  - Subsystem breakdown
  - Real plant names and IDs from ONS data
  
- **`examples/hydro_tree_example.jl`** 🌲 **[ADVANCED]**
  - Complete cascade analysis
  - Upstream/downstream relationships
  - Cascade root detection
  - Statistics by subsystem
  - Cycle detection
  
**Output Example**:
```
CASCADE: Paranapanema River (Southeast - 11 plants)
└─ 🏭 A.A. LAYDNER (#47)
   Capacity: 50.5 MW
   Storage: 3843-7008 hm³
   ⬇️
  └─ 🏭 PIRAJU (#48)
     Capacity: 40.0 MW
     ...
```

#### Parser Testing
- **`examples/parse_sample_case.jl`** 📄
  - Parse complete DESSEM case
  - Basic data extraction
  - Validation examples

- **`examples/test_ons_parsers.jl`** 🧪
  - Test with ONS official samples
  - Compatibility validation
  - Performance benchmarks

#### Other Examples
- **`examples/analyze_ons_files.jl`** 📊
  - Comprehensive ONS data analysis
  - Statistics generation
  - Data quality checks

- **`examples/test_operuh_parse.jl`** ⚙️
  - OPERUH parser testing
  - Constraint validation

- **`examples/verify_ons_compatibility.jl`** ✅
  - ONS compatibility verification
  - Format validation
  - Reference comparison

---

## 📝 Development Logs

Track project progress and understand development decisions.

### Recent Sessions
- **[Session 8 Summary](sessions/session8_summary.md)** 📅 *Latest*
  - Current session notes
  - Recent progress
  
- **[HIDR Documentation Update](sessions/HIDR_DOCUMENTATION_UPDATE.md)** 📚 *October 19, 2025*
  - HIDR parser documentation completion
  - 5 documentation files created/updated
  - ~1,510 lines of new documentation
  - 2 visualization examples
  - See: [Session Summary](sessions/SESSION_SUMMARY.md)

- **[Session 7 Summary](sessions/session7_summary.md)** 📅
  - Previous development work
  
- **[Session 6 Summary](sessions/session6_summary.md)** 📅
  - Earlier progress notes

- **[Session 5 Summary](sessions/session5_summary.md)** 📅
  - Historical development

### Project Summaries
- **[Session Summary](sessions/SESSION_SUMMARY.md)** 📋
  - Complete session overview
  - HIDR implementation details
  - Statistics and achievements

- **[Documentation Update](DOCUMENTATION_UPDATE.md)** 📝
  - Documentation improvement tracking
  - Structure changes
  - Content additions

- **[Reorganization Summary](REORGANIZATION_SUMMARY.md)** 🔄
  - Repository reorganization notes
  - Structure improvements
  - Migration guide

---

## 🧭 Planning & Status

Current project status and future plans.

### Status Tracking
- **[Tasks](planning/TASKS.md)** ✅
  - Current task list
  - Priority assignments
  - Implementation status
  - Next steps

### Compatibility
- **[ONS Compatibility Summary](planning/ONS_COMPATIBILITY_SUMMARY.md)** 🔄
  - ONS official format compatibility
  - Validation status
  - Known issues
  - Testing results

---

## 🗺️ Documentation Map

Visual overview of how documentation relates:

```
📚 DESSEM2Julia Docs
│
├─ 🚀 Getting Started
│  ├─ Quick Start Guide ──────────► First Steps
│  ├─ Project Context ────────────► Understand Goals
│  └─ Repository Structure ───────► Navigate Codebase
│
├─ 🏗️ Architecture
│  ├─ Architecture Overview ──────► System Design
│  └─ Type System ────────────────► Data Structures
│                                     │
│                                     └──► Entity Relationships
│
├─ 📖 File Formats
│  ├─ File Formats Summary ───────► All Formats + Status
│  ├─ DESSEM Complete Specs ──────► Detailed Specifications
│  ├─ Format Notes ───────────────► Implementation Tips
│  └─ Binary Files ───────────────► Binary Format Details
│
├─ 🔗 Data Relationships ★ CENTRAL HUB
│  ├─ Entity Relationships ───────► Complete Relationship Model
│  │  ├─ Subsystems
│  │  ├─ Hydro Plants ──────────┬─► HIDR Quick Reference
│  │  ├─ Thermal Plants         ├─► HIDR Binary Complete
│  │  ├─ Cascade Topology       └─► HIDR Entity Diagram
│  │  ├─ Query Examples ─────────► Usage Patterns
│  │  └─ Real-World Data ────────► ONS Samples
│  │
│  └─ HIDR Entity Diagram ────────► Visual Reference
│
├─ ⚙️ Parser Implementation
│  ├─ HIDR.DAT Parser (✅ Complete)
│  │  ├─ Quick Reference ─────────► Start Here
│  │  ├─ Binary Complete ─────────► Technical Details
│  │  └─ Entity Diagram ──────────► Relationships
│  │
│  ├─ OPERUT Implementation ───────► Thermal Constraints
│  ├─ IDESSEM Comparison ──────────► Reference Implementation
│  └─ Format Notes ────────────────► General Guidelines
│
├─ 💻 Examples
│  ├─ simple_hydro_tree.jl ────────► Cascade Visualization
│  ├─ hydro_tree_example.jl ───────► Advanced Analysis
│  ├─ parse_sample_case.jl ────────► Basic Parsing
│  └─ test_ons_parsers.jl ─────────► ONS Testing
│
└─ 📝 Development Logs
   ├─ Session Summaries ───────────► Progress Tracking
   ├─ HIDR Documentation Update ───► Recent Work
   └─ Tasks ───────────────────────► Current Status
```

---

## 🔍 How to Find Information

### I want to...

#### **...parse HIDR.DAT files**
1. Start: [HIDR Quick Reference](HIDR_QUICK_REFERENCE.md)
2. Examples: [Simple Hydro Tree](../examples/simple_hydro_tree.jl)
3. Details: [HIDR Binary Complete](HIDR_BINARY_COMPLETE.md)

#### **...understand cascade relationships**
1. Start: [Entity Relationships - Cascade Topology](ENTITY_RELATIONSHIPS.md#2-cascade-topology-river-basin)
2. Visual: [HIDR Entity Diagram](HIDR_ENTITY_DIAGRAM.md)
3. Examples: [Hydro Tree Example](../examples/hydro_tree_example.jl)

#### **...learn about DESSEM file formats**
1. Overview: [File Formats Summary](file_formats.md)
2. Details: [DESSEM Complete Specs](dessem-complete-specs.md)
3. Implementation: [Format Notes](FORMAT_NOTES.md)

#### **...understand data relationships**
1. **Start: [Entity Relationships](ENTITY_RELATIONSHIPS.md)** ⭐ **ESSENTIAL**
2. Visual: [HIDR Entity Diagram](HIDR_ENTITY_DIAGRAM.md)
3. Queries: [Entity Relationships - Query Examples](ENTITY_RELATIONSHIPS.md#query-examples)

#### **...get started with the project**
1. [Quick Start Guide](planning/QUICK_START_GUIDE.md)
2. [Project Context](planning/PROJECT_CONTEXT.md)
3. [Repository Structure](REPOSITORY_STRUCTURE.md)

#### **...implement a new parser**
1. [File Formats](file_formats.md) - Check status
2. [Format Notes](FORMAT_NOTES.md) - Guidelines
3. [HIDR Binary Complete](HIDR_BINARY_COMPLETE.md) - Reference example
4. [IDESSEM Comparison](parsers/idessem_comparison.md) - Compare with reference

#### **...understand the type system**
1. [Type System](type_system.md)
2. [Entity Relationships](ENTITY_RELATIONSHIPS.md)
3. [Architecture](architecture.md)

#### **...see working examples**
1. [Examples Directory](../examples/)
2. [Entity Relationships - Query Examples](ENTITY_RELATIONSHIPS.md#query-examples)
3. [HIDR Quick Reference](HIDR_QUICK_REFERENCE.md)

#### **...check project status**
1. [Tasks](planning/TASKS.md)
2. [File Formats - Status](file_formats.md)
3. [Session Summaries](sessions/)

---

## 📌 Essential Documents

Must-read documents for different roles:

### For New Users 🆕
1. [Quick Start Guide](planning/QUICK_START_GUIDE.md)
2. [Project Context](planning/PROJECT_CONTEXT.md)
3. [HIDR Quick Reference](HIDR_QUICK_REFERENCE.md) (for hydro analysis)

### For Developers 💻
1. **[Entity Relationships](ENTITY_RELATIONSHIPS.md)** ⭐ **MUST READ**
2. [Type System](type_system.md)
3. [Architecture Overview](architecture.md)
4. [Repository Structure](REPOSITORY_STRUCTURE.md)

### For Parser Developers ⚙️
1. [File Formats](file_formats.md)
2. [Format Notes](FORMAT_NOTES.md)
3. [HIDR Binary Complete](HIDR_BINARY_COMPLETE.md) (reference implementation)
4. [IDESSEM Comparison](parsers/idessem_comparison.md)

### For Data Analysts 📊
1. **[Entity Relationships](ENTITY_RELATIONSHIPS.md)** ⭐
2. [HIDR Quick Reference](HIDR_QUICK_REFERENCE.md)
3. [Simple Hydro Tree Example](../examples/simple_hydro_tree.jl)
4. [HIDR Entity Diagram](HIDR_ENTITY_DIAGRAM.md)

### For Contributors 🤝
1. [Project Context](planning/PROJECT_CONTEXT.md)
2. [Tasks](planning/TASKS.md)
3. [Architecture](architecture.md)
4. [Format Notes](FORMAT_NOTES.md)

---

## 🌟 Featured Content

### Recently Updated ⭐
- **[Entity Relationships](ENTITY_RELATIONSHIPS.md)** - Complete HIDR integration (+360 lines)
- **[HIDR Quick Reference](HIDR_QUICK_REFERENCE.md)** - NEW comprehensive guide
- **[HIDR Entity Diagram](HIDR_ENTITY_DIAGRAM.md)** - NEW visual reference
- **[Session Summary](sessions/SESSION_SUMMARY.md)** - Latest progress

### Most Comprehensive 📚
- **[Entity Relationships](ENTITY_RELATIONSHIPS.md)** - 1000+ lines, 15+ query examples
- **[DESSEM Complete Specs](dessem-complete-specs.md)** - All file format specifications
- **[HIDR Binary Complete](HIDR_BINARY_COMPLETE.md)** - Complete binary implementation

### Best Examples 💡
- **[Simple Hydro Tree](../examples/simple_hydro_tree.jl)** - Clean visualization
- **[Entity Relationships - Queries](ENTITY_RELATIONSHIPS.md#query-examples)** - 15+ patterns

---

## 📖 Reading Paths

Suggested reading orders for different learning goals:

### Path 1: Quick Start (1-2 hours)
```
1. Quick Start Guide
2. HIDR Quick Reference
3. Simple Hydro Tree Example
4. File Formats Summary
```

### Path 2: Deep Understanding (4-6 hours)
```
1. Project Context
2. Architecture Overview
3. Entity Relationships ★
4. Type System
5. HIDR Binary Complete
6. DESSEM Complete Specs
```

### Path 3: Parser Development (2-3 hours)
```
1. File Formats
2. Format Notes
3. HIDR Binary Complete (reference)
4. IDESSEM Comparison
5. Entity Relationships - Query Examples
```

### Path 4: Data Analysis (2-3 hours)
```
1. Entity Relationships ★
2. HIDR Quick Reference
3. HIDR Entity Diagram
4. Examples (all hydro examples)
5. ONS Compatibility Summary
```

---

## 🔗 External References

- **IDESSEM (Python)**: https://github.com/rjmalves/idessem
  - Reference implementation for comparison
  - Binary format specifications
  - See: [IDESSEM Comparison](parsers/idessem_comparison.md)

- **DESSEM Official**: ONS (Operador Nacional do Sistema Elétrico)
  - Official format specifications
  - Sample data files in `docs/Sample/`

---

## 📞 Support & Contribution

### Need Help?
1. Check this index for relevant documentation
2. Search in [Entity Relationships](ENTITY_RELATIONSHIPS.md) for data questions
3. Look at [Examples](../examples/) for code patterns
4. Review [Tasks](planning/TASKS.md) for current status

### Want to Contribute?
1. Read [Project Context](planning/PROJECT_CONTEXT.md)
2. Check [Tasks](planning/TASKS.md) for open items
3. Review [Format Notes](FORMAT_NOTES.md) for guidelines
4. See [HIDR Binary Complete](HIDR_BINARY_COMPLETE.md) as reference implementation

---

## 📊 Documentation Statistics

- **Total Documentation Files**: ~20
- **Lines of Documentation**: ~5,000+
- **Code Examples**: 20+
- **Query Patterns**: 15+
- **Real-World Examples**: 6 major cascades
- **Diagrams**: 10+

**Last Updated**: October 19, 2025

---

<p align="center">
  <strong>⭐ Star Documents</strong><br>
  <a href="ENTITY_RELATIONSHIPS.md">Entity Relationships</a> •
  <a href="HIDR_QUICK_REFERENCE.md">HIDR Quick Ref</a> •
  <a href="file_formats.md">File Formats</a> •
  <a href="planning/QUICK_START_GUIDE.md">Quick Start</a>
</p>

<p align="center">
  <sub>Navigate easily • Learn quickly • Build efficiently</sub>
</p>
