'use client';

import { useApproval } from '@/hooks/useApproval';

interface ApprovalButtonProps {
  ownerAddress: string | undefined;
}

export function ApprovalButton({ ownerAddress }: ApprovalButtonProps) {
  const { isApproved, isLoading, isPending, approve, error } = useApproval(ownerAddress);

  if (isLoading) {
    return (
      <div className="text-sm text-gray-500">
        Checking approval status...
      </div>
    );
  }

  if (isApproved) {
    return (
      <div className="flex items-center gap-2 text-sm text-green-600 dark:text-green-400">
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
        </svg>
        Approved for migration
      </div>
    );
  }

  return (
    <div className="flex flex-col items-center gap-2">
      <button
        onClick={approve}
        disabled={isPending}
        className="px-6 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg font-medium disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
      >
        {isPending ? 'Approving...' : 'Approve Migration Contract'}
      </button>
      {error && (
        <div className="text-sm text-red-500">
          Error: {error.message}
        </div>
      )}
      <p className="text-xs text-gray-500 dark:text-gray-400 max-w-sm text-center">
        You need to approve the migration contract to transfer your Chimpers.
      </p>
    </div>
  );
}
