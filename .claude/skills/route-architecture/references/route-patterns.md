# Route Architecture — Full Pattern Examples

## Pattern: Repository (Data Access)

```typescript
// ✅ CORRECT - Repository in _shared
// app/_shared/repositories/calls.repository.ts
export async function list(supabase: SupabaseClient) {
  const { data, error } = await supabase
    .from('calls')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data;
}

// Usage in server action
import { callsRepository } from '@/app/_shared/repositories/calls.repository';

export async function getCalls() {
  const supabase = await createClient();
  return callsRepository.list(supabase);
}
```

**Rules:**
- Always `select *` (never pick columns)
- Accept `SupabaseClient` as first parameter
- Use Supabase-generated types
- One repository per entity

## Pattern: Service (Business Logic)

```typescript
// ✅ CORRECT - Service for complex operation
// app/_shared/services/booking.service.ts
export async function createBookingWithNotification(
  supabase: SupabaseClient,
  data: CreateBookingInput
) {
  // Step 1: Create booking in database
  const booking = await bookingRepository.create(supabase, data);

  // Step 2: Create calendar event in Nylas
  await nylasService.createEvent(booking);

  // Step 3: Send confirmation email
  await emailService.sendBookingConfirmation(booking);

  return booking;
}
```

**When to create a service:**
- Operation involves 3+ steps
- Operation touches external services (Nylas, Stripe, etc.)
- Logic is reused across multiple actions
- Logic is too complex for inline action code

**When NOT to create a service:**
- Simple CRUD → Use repository directly
- Single-step operation → Inline in action

## Pattern: Server Actions

### Simple Route (1-2 actions)

```
route/
├── actions.ts           # Single file
└── page.tsx
```

```typescript
// actions.ts
'use server';

export async function createItem(input: CreateInput) {
  const supabase = await createClient();
  const result = await itemsRepository.create(supabase, input);
  revalidatePath('/items');
  return { success: true, data: result };
}
```

### Complex Route (3+ actions)

```
route/
├── actions/             # Folder with one file per action
│   ├── create-item.ts
│   ├── delete-item.ts
│   ├── update-item.ts
│   └── get-item-details.ts
└── page.tsx
```

## Pattern: Types and Validation

```typescript
// Route-specific types stay with route
// app/(protected)/dashboard/types.ts
export interface DashboardData {
  kpis: KpiMetrics;
  charts: ChartData;
}

// Shared types go to _shared
// app/_shared/types/calls.types.ts
export type CallRecord = Database['public']['Tables']['calls']['Row'];

// Validation schemas always in _shared
// app/_shared/validation/calls.schema.ts
import { z } from 'zod';

export const createCallSchema = z.object({
  leadId: z.string().uuid(),
  scheduledAt: z.date(),
  notes: z.string().optional(),
});
```

## Anti-Patterns

```typescript
// ❌ WRONG - Direct Supabase in action (use repository)
export async function createCall(data: CreateCallInput) {
  const supabase = await createClient();
  await supabase.from('calls').insert(data);  // Use repository!
}

// ❌ WRONG - Cross-route import
import { UserCard } from '../users/components/UserCard';  // FORBIDDEN

// ❌ WRONG - Business logic in action (use service)
export async function processPayment(paymentId: string) {
  // 50 lines of complex logic with external API calls...
  // This should be a service!
}

// ❌ WRONG - Types inline (use _shared/types or route types.ts)
interface CallData {  // Should use Database types!
  id: string;
  name: string;
}
```
