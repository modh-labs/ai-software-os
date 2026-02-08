// Reference: Full component template with Sheet detail pattern
// Usage: Copy and adapt for new entity card + detail views

"use client";

import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
	Sheet,
	SheetContent,
	SheetHeader,
	SheetTitle,
} from "@/components/ui/sheet";

interface ItemCardProps {
	item: Item;
	isExpanded: boolean;
	onToggleExpand: () => void;
}

/**
 * ItemCard Component
 *
 * Displays an item with expandable details panel.
 *
 * @example
 * ```tsx
 * <ItemCard
 *   item={itemData}
 *   isExpanded={expandedId === itemData.id}
 *   onToggleExpand={() => setExpandedId(itemData.id)}
 * />
 * ```
 */
export function ItemCard({ item, isExpanded, onToggleExpand }: ItemCardProps) {
	return (
		<>
			<Card
				className="cursor-pointer hover:bg-muted/50 transition-colors"
				onClick={onToggleExpand}
			>
				<CardHeader>
					<CardTitle className="text-foreground">{item.title}</CardTitle>
				</CardHeader>
				<CardContent>
					<p className="text-muted-foreground">{item.description}</p>
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

// Parent component pattern
export function ItemsList({ items }: { items: Item[] }) {
	const [expandedId, setExpandedId] = useState<string | null>(null);

	return (
		<div>
			{items.map((item) => (
				<ItemCard
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
