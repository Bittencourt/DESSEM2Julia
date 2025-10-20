# DESSEM2Julia Documentation Sitemap

> **📚 [Back to Documentation Index](INDEX.md)**

Visual overview of all documentation and how it interconnects.

---

## 🗺️ Complete Documentation Map

```
📚 DESSEM2Julia Documentation
│
├─ 📖 INDEX.md ★ CENTRAL HUB
│  └─ Links to all documentation with guided navigation
│
├─ 📘 README.md
│  └─ Main documentation landing page
│
├─ 🚀 Getting Started
│  ├─ planning/QUICK_START_GUIDE.md
│  ├─ planning/PROJECT_CONTEXT.md
│  └─ REPOSITORY_STRUCTURE.md
│
├─ 🏗️ Architecture & Design
│  ├─ architecture.md
│  ├─ type_system.md ────────┬──► Links to ENTITY_RELATIONSHIPS.md
│  └─ REORGANIZATION_SUMMARY.md
│
├─ 📖 File Formats & Specifications
│  ├─ file_formats.md ──────────► Master status tracker
│  ├─ dessem-complete-specs.md ─► Official specifications
│  ├─ FORMAT_NOTES.md ──────────► Implementation notes
│  └─ parsers/
│     ├─ BINARY_FILES.md
│     ├─ OPERUT_IMPLEMENTATION.md
│     └─ idessem_comparison.md
│
├─ 🔗 Data Relationships ★ ESSENTIAL
│  ├─ ENTITY_RELATIONSHIPS.md ──► Complete ER model (1000+ lines)
│  │  ├─ Subsystem relationships
│  │  ├─ Hydro plant relationships
│  │  ├─ Thermal plant relationships
│  │  ├─ Cascade topology
│  │  ├─ Cross-file references
│  │  └─ Query examples (15+)
│  │
│  └─ HIDR.DAT Relationships (Detailed)
│     ├─ HIDR_QUICK_REFERENCE.md ──► Usage patterns & queries
│     ├─ HIDR_BINARY_COMPLETE.md ──► Binary format (792 bytes)
│     └─ HIDR_ENTITY_DIAGRAM.md ───► Visual ER diagrams
│
├─ 💻 Examples & Code
│  └─ ../examples/ (at project root)
│     ├─ simple_hydro_tree.jl ────► Cascade visualization
│     ├─ hydro_tree_example.jl ───► Advanced analysis
│     ├─ parse_sample_case.jl ────► Basic parsing
│     ├─ test_ons_parsers.jl ─────► ONS testing
│     └─ [more examples...]
│
├─ 📊 Sample Data & Validation
│  └─ Sample/
│     ├─ ONS_VALIDATION.md
│     ├─ SAMPLE_VALIDATION.md
│     ├─ DS_ONS_102025_RV2D11/ ───► ONS official sample
│     ├─ DS_CCEE_102025_SEMREDE_RV0D28/
│     └─ DS_CCEE_102025_SEMREDE_RV1D04/
│
├─ 📝 Development & Planning
│  ├─ planning/
│  │  ├─ TASKS.md ───────────────► Current task list
│  │  ├─ PROJECT_CONTEXT.md ─────► Project goals
│  │  ├─ QUICK_START_GUIDE.md
│  │  └─ ONS_COMPATIBILITY_SUMMARY.md
│  │
│  └─ sessions/ (Development logs)
│     ├─ SESSION_SUMMARY.md ──────► Latest complete summary
│     ├─ HIDR_DOCUMENTATION_UPDATE.md
│     ├─ session8_summary.md
│     ├─ session7_summary.md
│     ├─ session6_summary.md
│     └─ session5_summary.md
│
├─ 🔧 Internal Documentation
│  ├─ DOCUMENTATION_UPDATE.md
│  └─ _NAVIGATION_TEMPLATE.md ───► Template for navigation

└─ 🗺️ This Document
   └─ SITEMAP.md ────────────────► You are here!
```

---

## 🔗 Key Interconnections

### File Format Documentation Flow
```
file_formats.md (Status Overview)
    │
    ├──► dessem-complete-specs.md (Official Specs)
    ├──► FORMAT_NOTES.md (Implementation Notes)
    ├──► parsers/BINARY_FILES.md (Binary Formats)
    └──► ENTITY_RELATIONSHIPS.md (Data Model)
```

### HIDR.DAT Documentation Cluster
```
HIDR_QUICK_REFERENCE.md (Start Here)
    │
    ├──► HIDR_BINARY_COMPLETE.md (Binary Format Details)
    │     └──► 792 bytes/plant, 111 fields
    │
    ├──► HIDR_ENTITY_DIAGRAM.md (Visual Diagrams)
    │     └──► 7 entity types, cascade topology
    │
    └──► ENTITY_RELATIONSHIPS.md § HIDR
          └──► Integration with other files
```

### Entity Relationship Documentation
```
ENTITY_RELATIONSHIPS.md (Central ER Model)
    │
    ├──► type_system.md (Julia Structs)
    ├──► HIDR_ENTITY_DIAGRAM.md (Hydro Specific)
    ├──► file_formats.md (Format Specs)
    └──► Examples (Query Patterns)
```

### Learning Paths
```
New User Path:
    QUICK_START_GUIDE.md
        → HIDR_QUICK_REFERENCE.md
        → simple_hydro_tree.jl
        → file_formats.md

Developer Path:
    PROJECT_CONTEXT.md
        → architecture.md
        → ENTITY_RELATIONSHIPS.md ★
        → type_system.md
        → HIDR_BINARY_COMPLETE.md

Parser Developer Path:
    file_formats.md
        → FORMAT_NOTES.md
        → HIDR_BINARY_COMPLETE.md (reference)
        → ENTITY_RELATIONSHIPS.md § Queries
```

---

## 📊 Documentation Statistics

### By Category

| Category | Files | Lines (approx) |
|----------|-------|----------------|
| **Getting Started** | 3 | 1,000 |
| **Architecture** | 3 | 1,500 |
| **File Formats** | 4 | 2,000 |
| **Data Relationships** | 4 | 2,500 |
| **Parser Docs** | 3 | 1,500 |
| **Examples** | 7 | 1,000 |
| **Samples & Validation** | 2 | 500 |
| **Planning** | 4 | 1,000 |
| **Sessions** | 6 | 2,000 |
| **Navigation** | 3 | 800 |
| **Total** | ~39 | ~14,000+ |

### Most Connected Documents

1. **ENTITY_RELATIONSHIPS.md** - Referenced by 10+ documents
2. **HIDR_QUICK_REFERENCE.md** - Part of 4-document cluster
3. **file_formats.md** - Links to 8+ documents
4. **INDEX.md** - Links to all 39 documents

### Newest Documents (Oct 19, 2025)

1. **INDEX.md** - Central navigation hub
2. **SITEMAP.md** - This document
3. **HIDR_QUICK_REFERENCE.md** - Usage patterns
4. **HIDR_ENTITY_DIAGRAM.md** - Visual ER diagrams
5. **SESSION_SUMMARY.md** - Latest session summary

---

## 🎯 Quick Access by Use Case

### I want to parse HIDR.DAT
```
START: HIDR_QUICK_REFERENCE.md
  → Examples: simple_hydro_tree.jl
  → Details: HIDR_BINARY_COMPLETE.md
  → Relationships: HIDR_ENTITY_DIAGRAM.md
```

### I want to understand cascade topology
```
START: ENTITY_RELATIONSHIPS.md § Cascade Topology
  → Visual: HIDR_ENTITY_DIAGRAM.md
  → Example: hydro_tree_example.jl
  → Queries: ENTITY_RELATIONSHIPS.md § Query Examples
```

### I want to implement a new parser
```
START: file_formats.md (check status)
  → Guidelines: FORMAT_NOTES.md
  → Reference: HIDR_BINARY_COMPLETE.md
  → Relationships: ENTITY_RELATIONSHIPS.md
  → Compare: parsers/idessem_comparison.md
```

### I want to understand the data model
```
START: ENTITY_RELATIONSHIPS.md ★ ESSENTIAL
  → Types: type_system.md
  → Hydro: HIDR_ENTITY_DIAGRAM.md
  → Architecture: architecture.md
```

### I want to get started quickly
```
START: QUICK_START_GUIDE.md
  → Context: PROJECT_CONTEXT.md
  → Examples: simple_hydro_tree.jl
  → Basics: HIDR_QUICK_REFERENCE.md
```

---

## 🔄 Cross-Reference Matrix

| Document | Links To | Linked From |
|----------|----------|-------------|
| INDEX.md | All (39) | README.md, All major docs |
| ENTITY_RELATIONSHIPS.md | 5 | 10+ |
| HIDR_QUICK_REFERENCE.md | 6 | 8 |
| HIDR_BINARY_COMPLETE.md | 5 | 7 |
| file_formats.md | 8 | 6 |
| type_system.md | 3 | 5 |

---

## 📍 Document Locations

### Root Level (`docs/`)
- INDEX.md ★
- README.md
- SITEMAP.md
- ENTITY_RELATIONSHIPS.md ★
- file_formats.md
- dessem-complete-specs.md
- FORMAT_NOTES.md
- architecture.md
- type_system.md
- REPOSITORY_STRUCTURE.md
- REORGANIZATION_SUMMARY.md
- DOCUMENTATION_UPDATE.md
- _NAVIGATION_TEMPLATE.md

### HIDR Cluster (`docs/`)
- HIDR_QUICK_REFERENCE.md
- HIDR_BINARY_COMPLETE.md
- HIDR_ENTITY_DIAGRAM.md

### Parsers (`docs/parsers/`)
- BINARY_FILES.md
- OPERUT_IMPLEMENTATION.md
- idessem_comparison.md

### Planning (`docs/planning/`)
- QUICK_START_GUIDE.md
- PROJECT_CONTEXT.md
- TASKS.md
- ONS_COMPATIBILITY_SUMMARY.md

### Sessions (`docs/sessions/`)
- SESSION_SUMMARY.md
- HIDR_DOCUMENTATION_UPDATE.md
- session8_summary.md
- session7_summary.md
- session6_summary.md
- session5_summary.md

### Samples (`docs/Sample/`)
- ONS_VALIDATION.md
- SAMPLE_VALIDATION.md
- DS_ONS_102025_RV2D11/ (directory)
- DS_CCEE_102025_SEMREDE_RV0D28/ (directory)
- DS_CCEE_102025_SEMREDE_RV1D04/ (directory)

### Examples (`examples/` at project root)
- simple_hydro_tree.jl
- hydro_tree_example.jl
- parse_sample_case.jl
- test_ons_parsers.jl
- analyze_ons_files.jl
- test_operuh_parse.jl
- verify_ons_compatibility.jl

---

## 🎨 Documentation Types

### 📘 Reference Documentation
- ENTITY_RELATIONSHIPS.md
- HIDR_ENTITY_DIAGRAM.md
- dessem-complete-specs.md
- type_system.md
- file_formats.md

### 📖 Guides & Tutorials
- QUICK_START_GUIDE.md
- HIDR_QUICK_REFERENCE.md
- FORMAT_NOTES.md
- PROJECT_CONTEXT.md

### ⚙️ Technical Implementation
- HIDR_BINARY_COMPLETE.md
- OPERUT_IMPLEMENTATION.md
- architecture.md
- parsers/BINARY_FILES.md

### 🗺️ Navigation & Meta
- INDEX.md ★
- README.md
- SITEMAP.md (this document)
- _NAVIGATION_TEMPLATE.md

### 📊 Status & Planning
- TASKS.md
- file_formats.md (status table)
- ONS_COMPATIBILITY_SUMMARY.md
- session summaries

### 📝 Examples & Code
- All files in `examples/`
- Query examples in ENTITY_RELATIONSHIPS.md
- Usage patterns in HIDR_QUICK_REFERENCE.md

---

## 🔍 Search Tips

### Find by Topic
- **Cascade Analysis**: ENTITY_RELATIONSHIPS.md, HIDR_ENTITY_DIAGRAM.md, hydro_tree_example.jl
- **Binary Formats**: HIDR_BINARY_COMPLETE.md, BINARY_FILES.md
- **Parser Status**: file_formats.md
- **Data Model**: ENTITY_RELATIONSHIPS.md, type_system.md
- **Getting Started**: QUICK_START_GUIDE.md, INDEX.md
- **Query Patterns**: ENTITY_RELATIONSHIPS.md § Query Examples, HIDR_QUICK_REFERENCE.md

### Find by File Type
- **HIDR.DAT**: HIDR_* files (3 docs), ENTITY_RELATIONSHIPS.md § Hydro
- **ENTDADOS**: ENTITY_RELATIONSHIPS.md § Subsystems, file_formats.md
- **OPERUT**: parsers/OPERUT_IMPLEMENTATION.md, ENTITY_RELATIONSHIPS.md § Thermal
- **Binary**: HIDR_BINARY_COMPLETE.md, BINARY_FILES.md

### Find by Skill Level
- **Beginner**: QUICK_START_GUIDE.md, HIDR_QUICK_REFERENCE.md, simple_hydro_tree.jl
- **Intermediate**: ENTITY_RELATIONSHIPS.md, type_system.md, hydro_tree_example.jl
- **Advanced**: HIDR_BINARY_COMPLETE.md, architecture.md, OPERUT_IMPLEMENTATION.md

---

**📚 [Back to Documentation Index](INDEX.md)** | **🏠 [Main README](README.md)**

<div align="center">
  <sub>Complete documentation sitemap • Navigate with confidence</sub>
</div>
