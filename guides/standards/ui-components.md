---
title: "UI Component Standards"
description: "UI component standards for all apps in the monorepo."
tags: ["react", "typescript"]
category: "standards"
author: "Imran Gardezi"
publishable: true
---
# UI Component Standards

> **Applies to:** All apps in the monorepo (web, admin, future apps)
> **Last Updated:** January 2026

This document defines UI component standards for all applications in your monorepo. Every app MUST use shadcn/ui components and follow these Tailwind patterns.

---

## Component System

### shadcn/ui is the Standard

**ALL interactive elements MUST use shadcn/ui components:**

```typescript
// RIGHT - shadcn components
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Select } from '@/components/ui/select';
import { Dialog } from '@/components/ui/dialog';
import { Sheet } from '@/components/ui/sheet';

<Button>Click me</Button>
<Input placeholder="Enter text" />
<Textarea />

// WRONG - Raw HTML elements
<button className="px-4 py-2 bg-blue-500">Click me</button>
<input className="border rounded px-3 py-2" />
<textarea className="w-full border rounded" />
```

### Component Location

```
components/ui/           # shadcn/ui base components
app/_shared/components/  # Custom shared components (3+ routes)
app/(protected)/route/components/  # Route-specific components
```

### Adding New shadcn Components

```bash
# Add a new component
npx shadcn-ui@latest add dialog

# Check for updates
npx shadcn-ui@latest diff button
```

---

## Design Tokens

### Use Semantic Colors

```typescript
// RIGHT - Semantic tokens (auto light/dark)
<Button className="bg-primary text-primary-foreground" />
<div className="border-border bg-background text-foreground" />
<Badge className="bg-destructive text-destructive-foreground" />

// WRONG - Hardcoded colors
<Button className="bg-violet-600 hover:bg-violet-700 text-white" />
<div className="border-gray-200 bg-white text-gray-900" />
```

### Available Tokens

| Token | Usage |
|-------|-------|
| `primary` | Primary actions, brand color |
| `secondary` | Secondary actions |
| `destructive` | Dangerous actions (delete, cancel) |
| `muted` | De-emphasized content |
| `accent` | Highlighted areas |
| `background` | Page background |
| `foreground` | Primary text |
| `border` | Borders, dividers |
| `ring` | Focus rings |

### Button Variants

```typescript
<Button variant="default">Primary Action</Button>
<Button variant="secondary">Secondary Action</Button>
<Button variant="destructive">Delete</Button>
<Button variant="outline">Outline Style</Button>
<Button variant="ghost">Ghost Style</Button>
<Button variant="link">Link Style</Button>
```

---

## Component Organization

### Single Route Usage

Keep components colocated with the route:

```
app/(protected)/calls/
├── components/
│   ├── CallTable.tsx      # Only used in calls
│   ├── CallFilters.tsx
│   └── CallItem.tsx
├── actions.ts
└── page.tsx
```

### Shared (3+ Routes)

Move to `_shared/components/` when used by 3+ routes:

```
app/_shared/components/
├── entity-list/           # Generic list patterns
├── timeline/              # Activity timeline
├── metrics/               # KPI cards, charts
└── detail-sections/       # Section layouts
```

### NEVER Cross-Route Import

```typescript
// WRONG - Cross-route import
import { UserTable } from '../users/components/UserTable';

// RIGHT - Move to _shared if needed by multiple routes
import { UserTable } from '@/app/_shared/components/UserTable';
```

---

## Sheet Pattern (Detail Views)

### Single Toggle Handler

```typescript
interface ItemProps {
  item: Item;
  isExpanded: boolean;
  onToggleExpand: () => void;  // Single handler
}

export function ItemComponent({ item, isExpanded, onToggleExpand }: ItemProps) {
  return (
    <>
      <button onClick={onToggleExpand}>{item.name}</button>

      {/* Pass toggle directly to onOpenChange */}
      <Sheet open={isExpanded} modal={true} onOpenChange={onToggleExpand}>
        <SheetContent>
          <ItemDetails itemId={item.id} />
        </SheetContent>
      </Sheet>
    </>
  );
}
```

### DON'T Use Separate onOpen/onClose

```typescript
// WRONG - Redundant handlers
interface ItemProps {
  onToggleExpand: () => void;
  onClose: () => void;  // Redundant!
}

<Sheet
  open={isExpanded}
  onOpenChange={(open) => {
    if (!open) onClose();  // Unnecessary complexity
  }}
>
```

### URL Sync with Deep Linking

```typescript
export function ItemsList({ items }: ItemsListProps) {
  const { expandedId, setExpandedId } = useEntityFiltersSync({
    idParamName: 'itemId',
  });

  return (
    <div>
      {items.map(item => (
        <ItemComponent
          key={item.id}
          item={item}
          isExpanded={expandedId === item.id}
          onToggleExpand={() =>
            setExpandedId(expandedId === item.id ? null : item.id)
          }
        />
      ))}
    </div>
  );
}
```

---

## Tailwind CSS Rules

### Use `cn()` for Conditional Classes

```typescript
import { cn } from '@/lib/utils';

<div
  className={cn(
    'px-4 py-2 rounded-md',          // Base classes
    isActive && 'bg-primary',         // Conditional
    isDisabled && 'opacity-50'        // Conditional
  )}
/>
```

### No Custom Theme Overrides

- Use shadcn/ui defaults
- Use CSS variables in `globals.css` for theme-wide changes
- Don't override component classes randomly

### Spacing Consistency

```typescript
// RIGHT - Consistent spacing tokens
<div className="space-y-4">
<div className="gap-4">
<div className="p-4 m-2">

// WRONG - Arbitrary values
<div className="p-[13px] m-[7px]">
```

### Responsive Design

```typescript
// Mobile-first responsive
<div className="flex flex-col md:flex-row">
<div className="w-full md:w-1/2 lg:w-1/3">
<div className="text-sm md:text-base lg:text-lg">
```

---

## Detail View Architecture

### Three-Layer Pattern

All entity detail views follow this structure:

```typescript
// 1. Container - Manages Sheet state
export function LeadDetailSheet({ open, onOpenChange, leadId }) {
  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent>
        <LeadDetail leadId={leadId} />
      </SheetContent>
    </Sheet>
  );
}

// 2. Detail - Assembles sections
export function LeadDetail({ leadId }) {
  const lead = await fetchLead(leadId);
  return (
    <div className="space-y-0 divide-y">
      <ContactSection lead={lead} />
      <NotesSection notes={lead.notes} />
      <CtaSection lead={lead} />
    </div>
  );
}

// 3. Sections - Read-only display
export function ContactSection({ lead }) {
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

### Section Standards

| Aspect | Standard |
|--------|----------|
| Headers | `text-sm font-semibold uppercase tracking-wide` |
| Layout | Flat sections with bottom borders only |
| Label-Value | Use `<InfoGrid>` + `<InfoItem>` or `<RowItem>` |
| Technical IDs | `font-mono text-xs` |
| Empty States | Icon + text (not blank) |
| Actions | Fixed CTA at bottom |

---

## Loading States

### Skeletons Match Layout

```typescript
// loading.tsx
export default function CallsLoading() {
  return (
    <div className="space-y-4">
      <Skeleton className="h-10 w-64" />  {/* Search bar */}
      <div className="space-y-2">
        <Skeleton className="h-16 w-full" />  {/* Row 1 */}
        <Skeleton className="h-16 w-full" />  {/* Row 2 */}
        <Skeleton className="h-16 w-full" />  {/* Row 3 */}
      </div>
    </div>
  );
}
```

### Use `useTransition` for Actions

```typescript
'use client'
import { useTransition } from 'react';

export function CallForm() {
  const [isPending, startTransition] = useTransition();

  function handleSubmit() {
    startTransition(async () => {
      await createCall(data);
    });
  }

  return (
    <Button disabled={isPending}>
      {isPending ? 'Creating...' : 'Create Call'}
    </Button>
  );
}
```

### Optimistic Updates

```typescript
import { useOptimistic } from 'react';

export function CallList({ calls }) {
  const [optimisticCalls, addOptimisticCall] = useOptimistic(
    calls,
    (state, newCall) => [...state, { ...newCall, pending: true }]
  );

  async function handleCreate(data) {
    addOptimisticCall(data);  // Instant UI update
    await createCall(data);   // Server mutation
  }
}
```

---

## Error Handling

### Error Boundary Per Route

```typescript
// error.tsx
'use client'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="flex flex-col items-center justify-center p-8">
      <h2 className="text-lg font-semibold">Something went wrong</h2>
      <p className="text-muted-foreground">{error.message}</p>
      <Button onClick={reset}>Try again</Button>
    </div>
  );
}
```

### Empty States

```typescript
// Not blank - show helpful message
{calls.length === 0 && (
  <div className="flex flex-col items-center p-8 text-center">
    <PhoneOff className="h-12 w-12 text-muted-foreground" />
    <h3 className="mt-4 font-semibold">No calls scheduled</h3>
    <p className="text-muted-foreground">
      Create your first call to get started
    </p>
    <Button className="mt-4">Schedule Call</Button>
  </div>
)}
```

---

## Accessibility

### Required Patterns

```typescript
// Labels for inputs
<Label htmlFor="email">Email</Label>
<Input id="email" type="email" />

// Button with icon needs aria-label
<Button aria-label="Close dialog" size="icon">
  <X className="h-4 w-4" />
</Button>

// Dialog descriptions
<Dialog>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Edit Profile</DialogTitle>
      <DialogDescription>
        Make changes to your profile here.
      </DialogDescription>
    </DialogHeader>
  </DialogContent>
</Dialog>
```

---

## Checklist for New Components

- [ ] Using shadcn/ui base components (no raw HTML elements)
- [ ] Semantic color tokens (not hardcoded colors)
- [ ] Colocated with route or in `_shared/` if 3+ routes
- [ ] `cn()` utility for conditional classes
- [ ] Loading skeleton matching final layout
- [ ] Error boundary with retry
- [ ] Empty state with helpful message
- [ ] Accessible labels and descriptions
- [ ] Responsive breakpoints if needed

---

## Related Documentation

- [Detail View Patterns](../patterns/detail-views.md) - Full architecture guide
- [Performance Patterns](../patterns/performance-patterns.md) - Suspense, optimistic updates
