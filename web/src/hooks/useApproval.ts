'use client';

import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';

const OLD_CHIMPERS_ADDRESS = '0x80336Ad7A747236ef41F47ed2C7641828a480BAA' as const;

// Placeholder - replace with actual deployed migration contract
const MIGRATION_CONTRACT_ADDRESS = '0x0000000000000000000000000000000000000000' as const;

const ERC721_ABI = [
  {
    name: 'isApprovedForAll',
    type: 'function',
    inputs: [
      { name: 'owner', type: 'address' },
      { name: 'operator', type: 'address' },
    ],
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    name: 'setApprovalForAll',
    type: 'function',
    inputs: [
      { name: 'operator', type: 'address' },
      { name: 'approved', type: 'bool' },
    ],
    outputs: [],
    stateMutability: 'nonpayable',
  },
] as const;

interface UseApprovalResult {
  isApproved: boolean | undefined;
  isLoading: boolean;
  isPending: boolean;
  approve: () => void;
  error: Error | null;
}

export function useApproval(ownerAddress: string | undefined): UseApprovalResult {
  // Check if approved
  const { data: isApproved, isLoading, refetch } = useReadContract({
    address: OLD_CHIMPERS_ADDRESS,
    abi: ERC721_ABI,
    functionName: 'isApprovedForAll',
    args: ownerAddress ? [ownerAddress as `0x${string}`, MIGRATION_CONTRACT_ADDRESS] : undefined,
    query: {
      enabled: !!ownerAddress,
    },
  });

  // Write approval
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();

  // Wait for transaction
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  // Refetch approval status after successful transaction
  if (isSuccess) {
    refetch();
  }

  const approve = () => {
    writeContract({
      address: OLD_CHIMPERS_ADDRESS,
      abi: ERC721_ABI,
      functionName: 'setApprovalForAll',
      args: [MIGRATION_CONTRACT_ADDRESS, true],
    });
  };

  return {
    isApproved: isApproved as boolean | undefined,
    isLoading,
    isPending: isPending || isConfirming,
    approve,
    error: writeError,
  };
}
