---
name: detail-view-pattern
description: Create entity detail views following your project's three-layer architecture. Use when building expandable detail sheets, drawers, modals, sidebars, or detail pages for entities like leads, calls, or audit logs. Enforces container/detail/section pattern, styling standards, and shared components.
allowed-tools: Read, Grep, Glob, Edit, Write
---

# Detail View Pattern Skill

## When This Skill Activates

This skill automatically activates when you:
- Create entity detail views (sheets, drawers, pages)
- Build detail sections for existing entities
- Discuss detail view architecture
- Work with `DetailSheet`, `Detail`, or `Section` components

## Three-Layer Architecture (MUST Follow)

All entity detail views follow this structure:

```
Container (Sheet/Drawer/Page)
├── State management (open/close)
├── Data mutations
└── Permission checks

Detail (Main content)
├── Layout assembly
├── Section composition
└── Conditional rendering

Sections (Display components)
├── Single responsibility
├── Read-only display
└── Shared across entities
```

## File Structure

```
app/(protected)/[entity]/components/
├── [Entity]DetailSheet.tsx       # Container
├── [Entity]Detail.tsx            # Main content
├── sections/
│   ├── ContactSection.tsx        # Domain-specific
│   ├── NotesSection.tsx          # Reusable
│   └── CtaSection.tsx            # Actions
└── [Entity]DetailSkeleton.tsx    # Loading state
```

## Core Rules

### 1. Container Pattern

```typescript
// ✅ CORRECT - Container manages state and mutations
export function LeadDetailSheet({
  open,
  onOpenChange,
  leadId
}: LeadDetailSheetProps) {
  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent className="w-full sm:max-w-xl">
        <LeadDetail leadId={leadId} />
      </SheetContent>
    </Sheet>
  );
}
```

### 2. Detail Pattern

```typescript
// ✅ CORRECT - Detail assembles sections with flat layout
export function LeadDetail({ leadId }: { leadId: string }) {
  const lead = await fetchLead(leadId);

  return (
    <div className="space-y-0 divide-y">
      <ContactSection lead={lead} />
      <NotesSection notes={lead.notes} />
      <CtaSection lead={lead} />
    </div>
  );
}
```

### 3. Section Pattern

```typescript
// ✅ CORRECT - Section displays one concern
export function ContactSection({ lead }: { lead: Lead }) {
  return (
    <SectionLayout title="CONTACT">
      <InfoGrid cols={2}>
        <InfoItem label="Name">{lead.name}</InfoItem>
        <InfoItem label="Email">{lead.email}</InfoItem>
      </InfoGrid>
    </SectionLayout>
  );
}
```

## Styling Standards

### Section Headers
```typescript
// ✅ CORRECT - Uppercase, tracking-wide
<h3 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
  CONTACT
</h3>
```

### Layout Flow
```typescript
// ✅ CORRECT - Flat sections with dividers
<div className="space-y-0 divide-y">
  {/* No rounded corners on sections */}
</div>
```

### Label-Value Pairs

**Vertical (InfoGrid):**
```typescript
<InfoGrid cols={2}>
  <InfoItem label="Name">{lead.name}</InfoItem>
  <InfoItem label="Status">{lead.status}</InfoItem>
</InfoGrid>
```

**Horizontal (RowItem):**
```typescript
<RowItem label="Created">{formatDate(lead.createdAt)}</RowItem>
```

### Technical IDs
```typescript
// ✅ CORRECT - Monospace for IDs
<span className="font-mono text-xs">{lead.id}</span>
```

## Shared Components

Use these from `@/app/_shared/components/`:

| Component | Purpose |
|-----------|---------|
| `SectionLayout` | Base section wrapper |
| `InfoGrid` + `InfoItem` | Vertical label-value layout |
| `RowItem` | Horizontal 50/50 layout |
| `NotesSection` | Generic notes (any entity) |
| `ActivityTimeline` | Event timeline |
| `ChangeDisplay` | Before/after changes |

## Implementation Checklist

Before shipping a detail view:

- [ ] Three-layer pattern (Container → Detail → Sections)
- [ ] Each section uses `SectionLayout`
- [ ] `space-y-0 divide-y` for flat section flow
- [ ] Uppercase section headers with `tracking-wide`
- [ ] `InfoGrid/InfoItem` or `RowItem` for label-value pairs
- [ ] Fixed CTA section at bottom (not inline)
- [ ] Loading skeleton matches final layout
- [ ] Error boundary with retry button
- [ ] Sections return `null` when empty (not blank space)
- [ ] Mutations use `useOptimistic` for instant feedback

## Anti-Patterns

```typescript
// ❌ WRONG - Rounded corners on sections
<div className="rounded-lg border p-4">

// ❌ WRONG - Inline actions in sections
<ContactSection lead={lead} onEdit={handleEdit} />

// ❌ WRONG - Mixed layout styles
<div className="space-y-4">  // Should be space-y-0 divide-y

// ❌ WRONG - Lowercase section headers
<h3 className="text-lg font-bold">Contact</h3>
```

## Reference

For complete documentation: `@apps/web/docs/patterns/detail-views.md`
