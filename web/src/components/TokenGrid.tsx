'use client';


interface TokenGridProps {
  tokenIds: bigint[];
  isLoading: boolean;
  selectedIds: Set<bigint>;
  onSelectionChange: (ids: Set<bigint>) => void;
}

export function TokenGrid({
  tokenIds,
  isLoading,
  selectedIds,
  onSelectionChange,
}: TokenGridProps) {
  const toggleToken = (id: bigint) => {
    const newSelected = new Set(selectedIds);
    if (newSelected.has(id)) {
      newSelected.delete(id);
    } else {
      newSelected.add(id);
    }
    onSelectionChange(newSelected);
  };

  const selectAll = () => {
    onSelectionChange(new Set(tokenIds));
  };

  const deselectAll = () => {
    onSelectionChange(new Set());
  };

  if (isLoading) {
    return (
      <div className="text-center py-8 text-gray-500">
        Loading your Chimpers...
      </div>
    );
  }

  if (tokenIds.length === 0) {
    return (
      <div className="text-center py-8 text-gray-500">
        No Chimpers found in your wallet.
      </div>
    );
  }

  return (
    <div className="w-full max-w-4xl">
      {/* Selection controls */}
      <div className="flex items-center justify-between mb-4">
        <span className="text-sm text-gray-600 dark:text-gray-400">
          {selectedIds.size} of {tokenIds.length} selected
        </span>
        <div className="flex gap-2">
          <button
            onClick={selectAll}
            disabled={selectedIds.size === tokenIds.length}
            className="px-3 py-1 text-sm rounded border border-gray-300 dark:border-gray-600 hover:bg-gray-100 dark:hover:bg-gray-800 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Select All
          </button>
          <button
            onClick={deselectAll}
            disabled={selectedIds.size === 0}
            className="px-3 py-1 text-sm rounded border border-gray-300 dark:border-gray-600 hover:bg-gray-100 dark:hover:bg-gray-800 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Deselect All
          </button>
        </div>
      </div>

      {/* Token grid */}
      <div className="grid grid-cols-4 sm:grid-cols-5 md:grid-cols-6 lg:grid-cols-8 gap-2">
        {tokenIds.map((id) => {
          const isSelected = selectedIds.has(id);
          return (
            <button
              key={id.toString()}
              onClick={() => toggleToken(id)}
              className={`
                relative aspect-square rounded-lg border-2 flex items-center justify-center
                transition-all hover:scale-105
                ${isSelected
                  ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/30'
                  : 'border-gray-200 dark:border-gray-700 hover:border-gray-400 dark:hover:border-gray-500'
                }
              `}
            >
              <span className="text-sm font-mono">#{id.toString()}</span>
              {isSelected && (
                <div className="absolute top-1 right-1 w-4 h-4 bg-blue-500 rounded-full flex items-center justify-center">
                  <svg
                    className="w-3 h-3 text-white"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                </div>
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}
