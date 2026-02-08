---
title: "UI Architecture and Theming"
description: "UI architecture strategy for sharing components, patterns, and experiences across apps."
tags: ["react", "architecture"]
category: "standards"
author: "Imran Gardezi"
publishable: true
---
# UI Architecture Standards

> **Applies to:** All apps in the monorepo (web, admin, future apps)
> **Last Updated:** January 2026

This document defines the UI architecture strategy for sharing components, patterns, and experiences across all your applications. It covers when to abstract, what to share, and how to maintain visual consistency.

---

## Philosophy

**Build domain UX on shared primitives.** Every app should feel consistent while serving its specific purpose.

```
┌─────────────────────────────────────────────────────────────┐
│                    Domain Components                         │
│         (LeadDetail, CallsDataGrid, AdminDemoTable)         │
├─────────────────────────────────────────────────────────────┤
│                   Shared Primitives                          │
│    (SectionLayout, InfoGrid, DataGrid, Badge, Timeline)     │
├─────────────────────────────────────────────────────────────┤
│                     shadcn/ui Base                           │
│         (Button, Dialog, Sheet, Card, Input, etc.)          │
├─────────────────────────────────────────────────────────────┤
│                    Tailwind + Theme                          │
│            (CSS variables, oklch colors, fonts)             │
└─────────────────────────────────────────────────────────────┘
```

---

## Package Strategy

### Current Structure

```
packages/
├── database-types/     # Supabase-generated types (shared)
├── mastra/             # AI agents (shared)
└── [future packages]
```

### Target Structure

```
packages/
├── database-types/     # Supabase-generated types
├── mastra/             # AI agents
├── ui-primitives/      # Section components, InfoGrid, layouts
├── ui-badges/          # Consolidated badge components
├── ui-datagrid/        # AG Grid wrapper + theming
├── ui-analytics/       # Charts, metrics, visualizations
└── ui-theme/           # Shared CSS variables, fonts, tokens
```

### Extraction Priority

| Package | Priority | Effort | Impact | Status |
|---------|----------|--------|--------|--------|
| `ui-primitives` | P0 | Low | High | Extract first |
| `ui-badges` | P1 | Low | Medium | Consolidate duplicates |
| `ui-theme` | P1 | Medium | High | Unify theming |
| `ui-datagrid` | P2 | Medium | Medium | After primitives |
| `ui-analytics` | P3 | High | Medium | When admin needs it |

---

## When to Abstract

### The 3+ Rule

**Extract to shared package when:**
- Used by **3+ routes** within one app, OR
- Used by **2+ apps** in the monorepo

### Abstraction Decision Tree

```
Is this component used in multiple apps?
├── Yes → Extract to /packages/ui-*
│
└── No → Is it used by 3+ routes in this app?
    ├── Yes → Move to app/_shared/components/
    │
    └── No → Keep colocated with route
```

### DON'T Prematurely Abstract

```typescript
// WRONG - Abstracting after first use
// "This might be useful elsewhere!"
packages/ui-primitives/LeadContactCard.tsx  // Too specific

// RIGHT - Keep domain-specific until proven reusable
apps/web/app/(protected)/leads/components/LeadContactCard.tsx
```

---

## Shared Primitives (ui-primitives)

### Section Components

These 8 components form the foundation for ALL detail views:

```typescript
// SectionLayout - Base wrapper for sections
<SectionLayout title="CONTACT" action={<Button size="sm">Edit</Button>}>
  {children}
</SectionLayout>

// InfoGrid + InfoItem - Vertical label-value pairs
<InfoGrid cols={2}>
  <InfoItem label="Name">{lead.name}</InfoItem>
  <InfoItem label="Email">{lead.email}</InfoItem>
  <InfoItem label="Phone">{lead.phone}</InfoItem>
  <InfoItem label="Source">{lead.source}</InfoItem>
</InfoGrid>

// RowItem - Horizontal 50/50 label-value
<RowItem label="Created">{formatDate(lead.created_at)}</RowItem>
<RowItem label="Status"><StatusBadge status={lead.status} /></RowItem>

// ChangeDisplay - Before/after visualization
<ChangeDisplay
  label="Price"
  before="$100"
  after="$150"
/>
```

### Section Standards

| Aspect | Standard |
|--------|----------|
| Headers | `text-sm font-semibold uppercase tracking-wide text-muted-foreground` |
| Layout | Flat sections with `divide-y` borders only |
| Spacing | `space-y-0` between sections (borders provide separation) |
| Empty | Return `null` or show icon + message |
| Actions | CTA section at bottom, not inline |

### Timeline Components

```typescript
// ActivityTimeline - Generic event timeline
<ActivityTimeline>
  <TimelineItem
    icon={<Phone />}
    title="Call completed"
    timestamp={call.completed_at}
    status="success"
  >
    <p>Duration: 45 minutes</p>
  </TimelineItem>
  <TimelineItem
    icon={<DollarSign />}
    title="Payment received"
    timestamp={payment.created_at}
    status="success"
  />
</ActivityTimeline>
```

---

## Detail View Architecture

### Three-Layer Pattern

ALL entity detail views follow this structure regardless of container type:

```
┌─────────────────────────────────────────┐
│           Container Layer               │
│   (Sheet, Dialog, Drawer, or Page)      │
│   - Manages open/close state            │
│   - Handles URL sync if needed          │
├─────────────────────────────────────────┤
│            Detail Layer                 │
│   (LeadDetail, CallDetail, etc.)        │
│   - Fetches data                        │
│   - Assembles sections                  │
│   - Handles mutations                   │
├─────────────────────────────────────────┤
│           Section Layer                 │
│   (ContactSection, NotesSection, etc.)  │
│   - Read-only display                   │
│   - Uses shared primitives              │
│   - Entity-agnostic when possible       │
└─────────────────────────────────────────┘
```

### Container Types

| Type | Use Case | Example |
|------|----------|---------|
| **Sheet** | Quick edit, side-by-side with list | Lead details from grid |
| **Dialog** | Focused task, confirmation | Delete confirmation |
| **Drawer** | Mobile-first, edge slide | Mobile navigation |
| **Page** | Deep focus, URL-addressable | `/leads/[id]` detail page |

### Implementation Pattern

```typescript
// 1. Container - Manages Sheet state
export function LeadDetailSheet({ open, onOpenChange, leadId }: Props) {
  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent className="w-[600px] sm:max-w-[600px]">
        <SheetHeader>
          <SheetTitle>Lead Details</SheetTitle>
        </SheetHeader>
        <LeadDetail leadId={leadId} />
      </SheetContent>
    </Sheet>
  );
}

// 2. Detail - Assembles sections
export function LeadDetail({ leadId }: { leadId: string }) {
  const lead = await fetchLead(leadId);

  return (
    <div className="space-y-0 divide-y">
      <ContactSection lead={lead} />
      <CompanySection company={lead.company} />
      <NotesSection
        notes={lead.notes}
        entityType="lead"
        entityId={leadId}
      />
      <ActivitySection activities={lead.activities} />
      <CtaSection lead={lead} />
    </div>
  );
}

// 3. Section - Read-only display (REUSABLE)
export function ContactSection({ lead }: { lead: Lead }) {
  return (
    <SectionLayout title="CONTACT">
      <InfoGrid cols={2}>
        <InfoItem label="Name">{lead.name}</InfoItem>
        <InfoItem label="Email">
          <EmailBadge email={lead.email} />
        </InfoItem>
        <InfoItem label="Phone">
          <PhoneBadge phone={lead.phone} />
        </InfoItem>
        <InfoItem label="Source">{lead.source}</InfoItem>
      </InfoGrid>
    </SectionLayout>
  );
}
```

---

## DataGrid Pattern (AG Grid)

### Shared Wrapper

```typescript
// packages/ui-datagrid/data-grid.tsx
import { AgGridReact } from "ag-grid-react";
import { shadcnGridThemeLight, shadcnGridThemeDark } from "./themes";

interface DataGridProps<T> {
  data: T[];
  columns: ColDef<T>[];
  columnConfig?: ColumnConfig;
  enableRowSelection?: boolean;
  selectionMode?: "singleRow" | "multiRow";
  onRowClicked?: (event: RowClickedEvent<T>) => void;
  loading?: boolean;
  emptyMessage?: string;
}

export function DataGrid<T>({
  data,
  columns,
  columnConfig,
  enableRowSelection = false,
  selectionMode = "singleRow",
  onRowClicked,
  loading,
  emptyMessage = "No data found",
}: DataGridProps<T>) {
  const theme = useTheme();

  return (
    <div className="h-full w-full">
      <AgGridReact
        rowData={data}
        columnDefs={columns}
        theme={theme === "dark" ? shadcnGridThemeDark : shadcnGridThemeLight}
        rowSelection={enableRowSelection ? { mode: selectionMode } : undefined}
        onRowClicked={onRowClicked}
        loadingOverlayComponent={LoadingOverlay}
        noRowsOverlayComponent={() => <EmptyState message={emptyMessage} />}
        // ... standard config
      />
    </div>
  );
}
```

### Domain Grid Pattern

```typescript
// apps/web/app/(protected)/calls/components/CallsDataGrid.tsx
import { DataGrid } from "@your-org/ui-datagrid";
import type { Call } from "@/app/_shared/types/calls";

const columns: ColDef<Call>[] = [
  {
    field: "lead.full_name",
    headerName: "Customer",
    flex: 1,
    cellRenderer: ({ value, data }) => (
      <div className="flex items-center gap-2">
        <Avatar name={value} size="sm" />
        <span>{value}</span>
      </div>
    ),
  },
  {
    field: "scheduled_at",
    headerName: "Date",
    width: 150,
    valueFormatter: ({ value }) => formatDate(value, userTimezone),
  },
  {
    field: "status",
    headerName: "Status",
    width: 120,
    cellRenderer: ({ value }) => <CallStatusBadge status={value} />,
  },
];

export function CallsDataGrid({ calls, onCallSelect }: Props) {
  return (
    <DataGrid
      data={calls}
      columns={columns}
      enableRowSelection
      selectionMode="singleRow"
      onRowClicked={(e) => onCallSelect(e.data.id)}
      emptyMessage="No calls scheduled"
    />
  );
}
```

### AG Grid Theming

```typescript
// packages/ui-datagrid/themes.ts
import { themeQuartz } from "ag-grid-community";

export const shadcnGridThemeLight = themeQuartz.withParams({
  backgroundColor: "hsl(var(--background))",
  foregroundColor: "hsl(var(--foreground))",
  borderColor: "hsl(var(--border))",
  headerBackgroundColor: "hsl(var(--muted))",
  rowHoverColor: "hsl(var(--accent))",
  selectedRowBackgroundColor: "hsl(var(--accent))",
  fontFamily: "var(--font-sans)",
  fontSize: 14,
  headerFontWeight: 500,
});

export const shadcnGridThemeDark = themeQuartz.withParams({
  // Dark mode variants
  backgroundColor: "#0a0a0a",
  foregroundColor: "#fafafa",
  // ... etc
});
```

---

## Badge Consolidation

### Current Problem

Badges are duplicated in 3+ locations:
- `/components/ui/badges/`
- `/app/_shared/components/badges/`
- `/app/(protected)/*/components/badges/`

### Target Structure

```
packages/ui-badges/
├── EmailBadge.tsx      # Clickable email with mail icon
├── PhoneBadge.tsx      # Clickable phone with phone icon
├── StatusBadge.tsx     # Generic status with semantic colors
├── StageBadge.tsx      # Booking intent stages
├── BookingLinkBadge.tsx # Link with colored indicator
├── types.ts
└── index.ts
```

### Badge Patterns

```typescript
// Generic status badge with semantic coloring
interface StatusBadgeProps {
  status: string;
  variant?: "default" | "outline" | "secondary";
  colorMap?: Record<string, string>;  // status -> color class
}

export function StatusBadge({ status, variant = "default", colorMap }: StatusBadgeProps) {
  const colorClass = colorMap?.[status] ?? "bg-muted text-muted-foreground";

  return (
    <Badge variant={variant} className={cn(colorClass)}>
      {status}
    </Badge>
  );
}

// Usage with domain-specific color map
const callStatusColors = {
  scheduled: "bg-blue-100 text-blue-800",
  completed: "bg-green-100 text-green-800",
  cancelled: "bg-red-100 text-red-800",
  no_show: "bg-yellow-100 text-yellow-800",
};

<StatusBadge status={call.status} colorMap={callStatusColors} />
```

---

## Theme Unification

### Shared CSS Variables

```css
/* packages/ui-theme/base.css */
@layer base {
  :root {
    /* Core brand colors */
    --brand-50: oklch(0.97 0.01 291);
    --brand-100: oklch(0.94 0.03 291);
    --brand-500: oklch(0.62 0.20 291);
    --brand-600: oklch(0.55 0.25 291);
    --brand-900: oklch(0.25 0.10 291);

    /* Semantic tokens */
    --primary: var(--brand-600);
    --primary-foreground: oklch(1 0 0);

    /* Typography */
    --font-sans: "Plus Jakarta Sans", system-ui, sans-serif;
    --font-mono: "JetBrains Mono", monospace;
  }

  .dark {
    --primary: var(--brand-500);
    --background: oklch(0.14 0.01 291);
    --foreground: oklch(0.98 0 0);
  }
}
```

### App-Specific Overrides

```css
/* apps/admin/app/globals.css */
@import "@your-org/ui-theme/base.css";

@layer base {
  :root {
    /* Admin-specific: darker sidebar */
    --sidebar-background: oklch(0.18 0.02 290);
    --sidebar-foreground: oklch(0.98 0 0);
  }
}
```

---

## Migration Guide

### Extracting to Shared Package

1. **Identify candidates** - Components used by 3+ routes or 2+ apps
2. **Create package** - `packages/ui-{name}/`
3. **Move components** - With all dependencies
4. **Update imports** - Search and replace
5. **Add to workspace** - Update root `package.json`
6. **Test both apps** - Verify no regressions

### Package Template

```
packages/ui-primitives/
├── package.json
├── tsconfig.json
├── src/
│   ├── SectionLayout.tsx
│   ├── InfoGrid.tsx
│   ├── InfoItem.tsx
│   ├── RowItem.tsx
│   ├── index.ts        # Re-exports
│   └── types.ts
├── README.md           # Usage documentation
└── CHANGELOG.md        # Version history
```

### package.json

```json
{
  "name": "@your-org/ui-primitives",
  "version": "0.1.0",
  "private": true,
  "main": "./src/index.ts",
  "types": "./src/index.ts",
  "exports": {
    ".": "./src/index.ts"
  },
  "peerDependencies": {
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "dependencies": {
    "clsx": "^2.0.0",
    "tailwind-merge": "^2.0.0"
  }
}
```

---

## Checklist for New Features

### Before Building UI

- [ ] Check if primitives exist in `@your-org/ui-primitives`
- [ ] Check if badges exist in `@your-org/ui-badges`
- [ ] Check if similar pattern exists in another route
- [ ] Design with three-layer detail view pattern in mind

### After Building UI

- [ ] Is this component used 3+ times? → Move to `_shared/`
- [ ] Could another app use this? → Consider extracting to package
- [ ] Does it follow section/detail patterns?
- [ ] Using semantic color tokens (not hardcoded)?
- [ ] Loading states and error handling included?

---

## Related Documentation

- [UI Components Standards](./ui-components.md) - shadcn/ui usage, Tailwind rules
- See: `docs/patterns/detail-views.md` - Implementation details
- See: `apps/web/app/(protected)/analytics/docs/component-catalog.md` - Chart library
