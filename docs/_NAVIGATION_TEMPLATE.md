# Documentation Navigation Footer

Add this to the bottom of documentation files for easy navigation:

```markdown
---

## 📚 Related Documentation

- **[Documentation Index](INDEX.md)** - Central hub for all documentation
- **[Entity Relationships](ENTITY_RELATIONSHIPS.md)** - Complete ER model
- **[File Formats](file_formats.md)** - Parser status and format overview
- **[Quick Start Guide](planning/QUICK_START_GUIDE.md)** - Get started quickly

### HIDR.DAT Documentation
- **[HIDR Quick Reference](HIDR_QUICK_REFERENCE.md)** - Common usage patterns
- **[HIDR Binary Complete](HIDR_BINARY_COMPLETE.md)** - Binary format details
- **[HIDR Entity Diagram](HIDR_ENTITY_DIAGRAM.md)** - Visual relationships

### Parser Implementation
- **[Format Notes](FORMAT_NOTES.md)** - Implementation guidelines
- **[Binary Files](parsers/BINARY_FILES.md)** - Binary format overview
- **[OPERUT Implementation](parsers/OPERUT_IMPLEMENTATION.md)** - Thermal operations
- **[IDESSEM Comparison](parsers/idessem_comparison.md)** - Reference implementation

### Examples & Tutorials
- **[Examples Directory](../examples/)** - Working code examples
- **[Entity Relationships § Queries](ENTITY_RELATIONSHIPS.md#query-examples)** - Query patterns

---

<div align="center">
  <sub>Part of <a href="INDEX.md">DESSEM2Julia Documentation</a></sub>
</div>
```

## Usage

At the bottom of each major documentation file, add:

```markdown
---

**📚 [Back to Documentation Index](INDEX.md)**

**Related**: [Entity Relationships](ENTITY_RELATIONSHIPS.md) • [HIDR Quick Reference](HIDR_QUICK_REFERENCE.md) • [File Formats](file_formats.md)
```

Customize the "Related" links based on the document's topic.
