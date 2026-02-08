// Reference: DataGrid with shadcn theming and Sheet detail pattern
// Usage: Copy and adapt for new data table views

"use client";

import { useState } from "react";
import { DataGrid } from "@/components/ui/data-grid";
import {
	Sheet,
	SheetContent,
	SheetHeader,
	SheetTitle,
} from "@/components/ui/sheet";

interface ItemGridProps {
	items: Item[];
}

export function ItemGrid({ items }: ItemGridProps) {
	const [expandedId, setExpandedId] = useState<string | null>(null);
	const expandedItem = items.find((item) => item.id === expandedId);

	return (
		<>
			<DataGrid
				data={items}
				columns={columns}
				columnConfig={columnConfig}
				enableRowSelection
				selectionMode="singleRow"
				onRowSelected={(event) => {
					if (event.node.isSelected()) {
						setExpandedId(event.data.id);
					}
				}}
			/>

			<Sheet open={!!expandedItem} onOpenChange={() => setExpandedId(null)}>
				<SheetContent className="w-full sm:max-w-2xl">
					<SheetHeader>
						<SheetTitle>{expandedItem?.title}</SheetTitle>
					</SheetHeader>
					{/* Detail content */}
				</SheetContent>
			</Sheet>
		</>
	);
}
