// Reference: Full server action template with all patterns
// Usage: Copy and adapt for new route actions

"use server";

import { revalidatePath } from "next/cache";
import { createModuleLogger } from "@/app/_shared/lib/logger";
import { createClient } from "@/app/_shared/lib/supabase/server";
import type {
	EntityInsert,
	EntityUpdate,
} from "@/app/_shared/repositories/entity.repository";
import {
	createEntity,
	deleteEntity,
	getEntityById,
	updateEntity,
} from "@/app/_shared/repositories/entity.repository";

const logger = createModuleLogger("entity-actions");

// Types for action responses
type ActionResponse<T> =
	| { success: true; data: T }
	| { success: false; error: string };

/**
 * Get entity by ID
 */
export async function getEntityAction(
	id: string,
): Promise<ActionResponse<Entity>> {
	logger.info({ id }, "Server action: getEntity called");

	try {
		const supabase = await createClient();
		const entity = await getEntityById(supabase, id);

		if (!entity) {
			return { success: false, error: "Entity not found" };
		}

		return { success: true, data: entity };
	} catch (error) {
		logger.error({ error, id }, "Server action: getEntity failed");
		return { success: false, error: "Failed to fetch entity" };
	}
}

/**
 * Create new entity
 */
export async function createEntityAction(
	input: EntityInsert,
): Promise<ActionResponse<Entity>> {
	logger.info("Server action: createEntity called");

	try {
		const supabase = await createClient();
		const entity = await createEntity(supabase, input);

		// Cache invalidation
		revalidatePath("/entities");
		revalidatePath("/dashboard");

		logger.info({ entityId: entity.id }, "Entity created successfully");
		return { success: true, data: entity };
	} catch (error) {
		logger.error({ error }, "Server action: createEntity failed");
		return { success: false, error: "Failed to create entity" };
	}
}

/**
 * Update existing entity
 */
export async function updateEntityAction(
	id: string,
	updates: EntityUpdate,
): Promise<ActionResponse<Entity>> {
	logger.info({ id }, "Server action: updateEntity called");

	try {
		const supabase = await createClient();
		const entity = await updateEntity(supabase, id, updates);

		// Cache invalidation
		revalidatePath("/entities");
		revalidatePath(`/entities/${id}`);
		revalidatePath("/dashboard");

		logger.info({ entityId: entity.id }, "Entity updated successfully");
		return { success: true, data: entity };
	} catch (error) {
		logger.error({ error, id }, "Server action: updateEntity failed");
		return { success: false, error: "Failed to update entity" };
	}
}

/**
 * Delete entity
 */
export async function deleteEntityAction(
	id: string,
): Promise<ActionResponse<void>> {
	logger.info({ id }, "Server action: deleteEntity called");

	try {
		const supabase = await createClient();
		await deleteEntity(supabase, id);

		// Cache invalidation
		revalidatePath("/entities");
		revalidatePath("/dashboard");

		logger.info({ entityId: id }, "Entity deleted successfully");
		return { success: true, data: undefined };
	} catch (error) {
		logger.error({ error, id }, "Server action: deleteEntity failed");
		return { success: false, error: "Failed to delete entity" };
	}
}

// --- Client Component Usage ---
// "use client";
//
// import { useTransition } from "react";
// import { useRouter } from "next/navigation";
// import { createEntityAction } from "../actions";
//
// export function EntityForm() {
//   const router = useRouter();
//   const [isPending, startTransition] = useTransition();
//
//   async function handleSubmit(formData: FormData) {
//     startTransition(async () => {
//       const result = await createEntityAction({
//         title: formData.get("title") as string,
//       });
//
//       if (result.success) {
//         router.refresh();
//       } else {
//         // Show error toast with result.error
//       }
//     });
//   }
//
//   return (
//     <form action={handleSubmit}>
//       <Button type="submit" disabled={isPending}>
//         {isPending ? "Creating..." : "Create"}
//       </Button>
//     </form>
//   );
// }
