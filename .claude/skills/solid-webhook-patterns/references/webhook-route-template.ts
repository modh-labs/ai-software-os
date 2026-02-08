// Reference: Complete webhook route template using handler registry pattern
// Usage: Copy and adapt for new webhook provider routes

import * as Sentry from "@sentry/nextjs";
import { NextResponse } from "next/server";
import { createServiceRoleClient } from "@/app/_shared/lib/supabase/server";
import { createWebhookLogger } from "@/app/_shared/lib/webhooks";
import { WEBHOOK_HANDLERS } from "./lib/handler-registry";
import { resolveOrganization } from "./lib/resolve-organization";
import { verifySignature } from "./lib/verify-signature";

export async function POST(req: Request) {
	const startTime = Date.now();
	const rawBody = await req.text();

	// 1. Verify signature
	const signature = req.headers.get("x-provider-signature");
	if (!signature || !verifySignature(rawBody, signature)) {
		return NextResponse.json({ error: "Invalid signature" }, { status: 401 });
	}

	// 2. Parse payload
	const body = JSON.parse(rawBody);
	const eventType = body.type;

	// 3. Get handler from registry
	const handler = WEBHOOK_HANDLERS[eventType];
	if (!handler) {
		// ACK unknown events to prevent retries
		return NextResponse.json({ success: true });
	}

	// 4. Validate payload
	const validation = handler.schema.safeParse(body);
	if (!validation.success) {
		return NextResponse.json(
			{ error: "Validation failed", details: validation.error.issues },
			{ status: 400 },
		);
	}

	// 5. Build context
	const organizationId = handler.requiresOrganization
		? await resolveOrganization("provider", body)
		: undefined;

	const context: WebhookContext = {
		organizationId,
		supabase: await createServiceRoleClient(),
		logger: createWebhookLogger({
			provider: "provider",
			handler: eventType,
			eventType,
			organizationId,
		}),
	};

	// 6. Execute handler
	try {
		Sentry.setTags({ "webhook.event_type": eventType });
		const _result = await handler.execute(validation.data, context);

		const duration = Date.now() - startTime;
		return NextResponse.json({ success: true, duration_ms: duration });
	} catch (error) {
		Sentry.captureException(error);
		return NextResponse.json({ error: "Handler failed" }, { status: 500 });
	}
}
