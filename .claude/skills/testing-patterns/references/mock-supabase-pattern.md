# Mock Supabase Client Pattern

## Usage

```typescript
import { createMockSupabaseClient } from "@/test/mocks/supabase.mock";

const mockSupabase = createMockSupabaseClient();
```

## Mocking Query Chains

```typescript
// Mock insert → select → single chain
mockSupabase._chain.insert.mockReturnValue(mockSupabase._chain);
mockSupabase._chain.select.mockReturnValue(mockSupabase._chain);
mockSupabase._chain.single.mockResolvedValue({
  data: mockData,
  error: null,
});

// Mock select → eq → order chain
mockSupabase._chain.select.mockReturnValue(mockSupabase._chain);
mockSupabase._chain.eq.mockReturnValue(mockSupabase._chain);
mockSupabase._chain.order.mockResolvedValue({
  data: [mockItem1, mockItem2],
  error: null,
});
```

## Verifying Calls

```typescript
expect(mockSupabase.from).toHaveBeenCalledWith("table_name");
expect(mockSupabase._chain.insert).toHaveBeenCalledWith(expectedData);
expect(mockSupabase._chain.eq).toHaveBeenCalledWith("id", expectedId);
```

## Mocking Errors

```typescript
mockSupabase._chain.single.mockResolvedValue({
  data: null,
  error: { message: "Not found", code: "PGRST116" },
});
```

## Type Casting

```typescript
import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/app/_shared/lib/supabase/database.types";

const result = await myRepoFunction(
  mockSupabase as unknown as SupabaseClient<Database>,
  input
);
```
