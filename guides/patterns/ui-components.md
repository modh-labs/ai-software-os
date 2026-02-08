---
title: "UI Component Patterns"
description: "Component patterns and conventions for your application's UI layer."
tags: ["react", "typescript", "patterns"]
category: "patterns"
author: "Imran Gardezi"
publishable: true
---
# UI Component Patterns

## shadcn/ui Components

**Standard import location:**

```typescript
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
```

### Design Tokens

Use semantic color tokens that automatically apply to all components:

```typescript
// Primary Colors
<Button className="bg-primary text-primary-foreground" />
<div className="border border-primary" />

// Variants
<Button variant="secondary" />
<Button variant="destructive" />
<Button variant="outline" />
<Button variant="ghost" />

// AVOID: Hardcoded colors
<Button className="bg-violet-600 hover:bg-violet-700" />
```

### Component Organization

1. shadcn/ui Base Components → `@/components/ui/`
2. Single Route → Keep in route directory
3. Custom Shared (3+ routes) → `app/_shared/components/`

### Adding New Components

```bash
# Add a new shadcn component
bunx shadcn-ui@latest add dialog

# Update an existing component
bunx shadcn-ui@latest diff button
```

---

## Sheet Component Pattern (URL-Synced Detail Views)

**Use Case:** Expandable detail panels for list items with URL deep-linking support.

### Key Principles

1. **Single toggle handler** - Don't use separate `onOpen` and `onClose` callbacks
2. **URL sync via query params** - Managed by `useEntityFiltersSync` or similar hook
3. **Simple Sheet `onOpenChange`** - Pass the toggle handler directly

### Correct Pattern

```typescript
// List Item Component
interface ItemProps {
  item: Item;
  isExpanded: boolean;
  onToggleExpand: () => void; // Single toggle handler
}

export function ItemComponent({ item, isExpanded, onToggleExpand }: ItemProps) {
  return (
    <>
      {/* Clickable row */}
      <button onClick={onToggleExpand}>
        {item.name}
      </button>

      {/* Detail sheet - onOpenChange calls toggle directly */}
      <Sheet open={isExpanded} modal={true} onOpenChange={onToggleExpand}>
        <SheetContent>
          <ItemDetails itemId={item.id} />
        </SheetContent>
      </Sheet>
    </>
  );
}

// Parent List Component
export function ItemsList({ items, deepLinkId }: ItemsListProps) {
  const { expandedId, setExpandedId } = useEntityFiltersSync({
    idParamName: 'itemId', // URL param name
    // ... other config
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

### Anti-pattern (DON'T DO THIS)

```typescript
// Redundant handlers
interface ItemProps {
  item: Item;
  isExpanded: boolean;
  onToggleExpand: () => void;
  onClose: () => void; // Redundant!
}

export function ItemComponent({ item, isExpanded, onToggleExpand, onClose }: ItemProps) {
  return (
    <Sheet
      open={isExpanded}
      onOpenChange={(open) => {
        // Complex logic, ignores toggle pattern
        if (!open) {
          onClose();
        }
      }}
    >
      {/* ... */}
    </Sheet>
  );
}
```

### Why This Pattern Works

- Sheet's `onOpenChange` receives boolean but we don't need it - toggle is stateless
- `setExpandedId(null)` removes the URL param automatically (via `useEntityFiltersSync`)
- Works with all close methods: overlay click, Esc key, X button
- Supports deep linking via URL params (e.g., `?itemId=123`)
- Browser back/forward buttons work correctly

### Reference Implementations

- `app/(protected)/calls/components/CallItem.tsx` (canonical example)
- `app/(protected)/leads/components/LeadItem.tsx` (follows pattern)

---

## Styling Rules

### Use shadcn/ui Components ONLY

- **NEVER use raw HTML elements** (`<button>`, `<input>`, `<textarea>`, `<select>`, etc.)
- **ALWAYS import from `@/components/ui/`** for every interactive element
- If a shadcn component exists, use it instead of HTML + Tailwind classnames

```typescript
// WRONG - Raw HTML with Tailwind
<button className="px-3 py-2 bg-blue-500 text-white rounded">Click</button>
<textarea className="w-full border rounded-md px-3 py-2" />
<input type="text" className="border rounded-md px-3 py-2" />

// RIGHT - shadcn Components
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Input } from '@/components/ui/input'

<Button>Click</Button>
<Textarea />
<Input />
```

### Tailwind CSS Rules

- Use shadcn/ui defaults - no overrides
- No manual Tailwind config overrides unless theme-wide
- Use `cn()` utility from `@/lib/utils` for conditional classes
- Keep className props clean and readable
- Don't override component classes randomly
- Use CSS variables for theming (defined in `globals.css`)
- Never add custom inline styles unless absolutely necessary
