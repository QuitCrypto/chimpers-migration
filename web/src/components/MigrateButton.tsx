'use client';

import { useMigrate } from '@/hooks/useMigrate';
import { useApproval } from '@/hooks/useApproval';

interface MigrateButtonProps {
  selectedIds: Set<bigint>;
  ownerAddress: string | undefined;
  onSuccess: () => void;
}

export function MigrateButton({ selectedIds, ownerAddress, onSuccess }: MigrateButtonProps) {
  const { isApproved } = useApproval(ownerAddress);
  const { migrate, isPending, isSuccess, error, reset } = useMigrate();

  const handleMigrate = () => {
    if (selectedIds.size === 0) return;
    migrate(Array.from(selectedIds));
  };

  // Call onSuccess when migration succeeds
  if (isSuccess) {
    onSuccess();
    reset();
    return (
      <div className="flex flex-col items-center gap-2 p-4 bg-green-50 dark:bg-green-900/20 rounded-lg">
        <svg className="w-8 h-8 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
        </svg>
        <span className="text-green-600 dark:text-green-400 font-medium">
          Migration successful!
        </span>
        <p className="text-sm text-gray-600 dark:text-gray-400">
          Your Chimpers have been migrated to the new collection.
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-col items-center gap-2">
      <button
        onClick={handleMigrate}
        disabled={!isApproved || selectedIds.size === 0 || isPending}
        className="px-8 py-3 bg-green-500 hover:bg-green-600 text-white rounded-lg font-medium text-lg disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
      >
        {isPending
          ? 'Migrating...'
          : `Migrate ${selectedIds.size} Chimper${selectedIds.size !== 1 ? 's' : ''}`}
      </button>
      {!isApproved && selectedIds.size > 0 && (
        <p className="text-sm text-amber-600 dark:text-amber-400">
          Please approve the migration contract first.
        </p>
      )}
      {error && (
        <div className="text-sm text-red-500">
          Error: {error.message}
        </div>
      )}
    </div>
  );
}
