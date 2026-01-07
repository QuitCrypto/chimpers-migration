'use client';

import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';

// Placeholder - replace with actual deployed migration contract
const MIGRATION_CONTRACT_ADDRESS = '0x0000000000000000000000000000000000000000' as const;

const MIGRATION_ABI = [
  {
    name: 'claimBatch',
    type: 'function',
    inputs: [{ name: 'tokenIds', type: 'uint256[]' }],
    outputs: [],
    stateMutability: 'nonpayable',
  },
] as const;

interface UseMigrateResult {
  migrate: (tokenIds: bigint[]) => void;
  isPending: boolean;
  isSuccess: boolean;
  error: Error | null;
  reset: () => void;
}

export function useMigrate(): UseMigrateResult {
  const { writeContract, data: hash, isPending, error: writeError, reset } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const migrate = (tokenIds: bigint[]) => {
    writeContract({
      address: MIGRATION_CONTRACT_ADDRESS,
      abi: MIGRATION_ABI,
      functionName: 'claimBatch',
      args: [tokenIds],
    });
  };

  return {
    migrate,
    isPending: isPending || isConfirming,
    isSuccess,
    error: writeError,
    reset,
  };
}
