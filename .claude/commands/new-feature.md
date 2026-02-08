---
description: Scaffold a new feature with route, actions, components, and types
argument-hint: [feature_name]
allowed-tools: Read, Write, Bash, Grep, Glob
---

# New Feature Command

Scaffold a new feature with proper structure and patterns.

**Feature Name**: `$ARGUMENTS`

## What This Command Creates

```
app/(protected)/$ARGUMENTS/
├── page.tsx                 # Server Component with data fetching
├── actions.ts               # Server Actions (colocated)
├── components/
│   ├── ${Feature}List.tsx   # Main list component
│   ├── ${Feature}Item.tsx   # Individual item with Sheet details
│   └── ${Feature}Form.tsx   # Create/edit form
└── types.ts                 # Route-specific types (if needed)
```

## Step 1: Gather Requirements

I'll ask about your feature:

1. **What data does this feature work with?**
   - Existing table(s)?
   - Need new table(s)?

2. **What are the main operations?**
   - List/view items
   - Create new items
   - Edit existing items
   - Delete items

3. **Does it need a detail view?**
   - Sheet panel (like Calls)?
   - Separate page?

## Step 2: Create Directory Structure

```bash
mkdir -p app/(protected)/$ARGUMENTS/components
```

## Step 3: Create Server Component Page

```typescript
// app/(protected)/$ARGUMENTS/page.tsx
import { createClient } from "@/app/_shared/lib/supabase/server";
import { get${Feature}s } from "@/app/_shared/repositories/${feature}.repository";
import { ${Feature}PageClient } from "./components/${Feature}PageClient";

export default async function ${Feature}Page() {
  const supabase = await createClient();
  const items = await get${Feature}s(supabase);

  return <${Feature}PageClient items={items} />;
}
```

## Step 4: Create Server Actions

```typescript
// app/(protected)/$ARGUMENTS/actions.ts
"use server";

import { revalidatePath } from "next/cache";
import { createModuleLogger } from "@/app/_shared/lib/logger";
import { createClient } from "@/app/_shared/lib/supabase/server";
import {
  create${Feature},
  update${Feature},
  delete${Feature},
} from "@/app/_shared/repositories/${feature}.repository";

const logger = createModuleLogger("${feature}-actions");

export async function create${Feature}Action(input: ${Feature}Insert) {
  logger.info("Creating ${feature}");

  try {
    const supabase = await createClient();
    const item = await create${Feature}(supabase, input);

    revalidatePath("/${feature}s");
    return { success: true, data: item };
  } catch (error) {
    logger.error({ error }, "Failed to create ${feature}");
    return { success: false, error: "Failed to create ${feature}" };
  }
}

// ... update and delete actions
```

## Step 5: Create Components

### List Component (Client)

```typescript
// app/(protected)/$ARGUMENTS/components/${Feature}List.tsx
"use client";

import { useState } from "react";
import { ${Feature}Item } from "./${Feature}Item";

export function ${Feature}List({ items }: { items: ${Feature}[] }) {
  const [expandedId, setExpandedId] = useState<string | null>(null);

  return (
    <div className="space-y-2">
      {items.map((item) => (
        <${Feature}Item
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

### Item Component with Sheet

```typescript
// app/(protected)/$ARGUMENTS/components/${Feature}Item.tsx
"use client";

import { Sheet, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { Card, CardContent } from "@/components/ui/card";

interface ${Feature}ItemProps {
  item: ${Feature};
  isExpanded: boolean;
  onToggleExpand: () => void;
}

export function ${Feature}Item({ item, isExpanded, onToggleExpand }: ${Feature}ItemProps) {
  return (
    <>
      <Card
        className="cursor-pointer hover:bg-muted/50 transition-colors"
        onClick={onToggleExpand}
      >
        <CardContent className="p-4">
          <h3 className="font-medium text-foreground">{item.title}</h3>
          <p className="text-sm text-muted-foreground">{item.description}</p>
        </CardContent>
      </Card>

      <Sheet open={isExpanded} onOpenChange={onToggleExpand}>
        <SheetContent className="w-full sm:max-w-2xl">
          <SheetHeader>
            <SheetTitle>{item.title}</SheetTitle>
          </SheetHeader>
          {/* Detail content */}
        </SheetContent>
      </Sheet>
    </>
  );
}
```

## Step 6: Create Repository (if needed)

If the feature needs a new table:

1. First create the schema: `/create-migration add_${feature}_table`
2. Then create repository at `app/_shared/repositories/${feature}.repository.ts`

## Checklist

- [ ] Directory structure created
- [ ] Server Component page created
- [ ] Server Actions created with proper patterns
- [ ] List component with expandable items
- [ ] Item component with Sheet details
- [ ] Form component for create/edit
- [ ] Repository exists (or created)
- [ ] All imports use correct paths
