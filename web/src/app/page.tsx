'use client';

import { useState } from 'react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount } from 'wagmi';
import { useUserChimpers } from '@/hooks/useUserChimpers';
import { TokenGrid } from '@/components/TokenGrid';

export default function Home() {
  const { address, isConnected } = useAccount();
  const { tokenIds, isLoading, error } = useUserChimpers(address);
  const [selectedIds, setSelectedIds] = useState<Set<bigint>>(new Set());

  return (
    <div className="min-h-screen flex flex-col items-center p-8 font-[family-name:var(--font-geist-sans)]">
      <main className="flex flex-col gap-8 items-center text-center w-full max-w-4xl">
        <h1 className="text-4xl font-bold mt-8">Chimpers Migration</h1>
        <p className="text-gray-600 dark:text-gray-400 max-w-md">
          Connect your wallet to migrate your Chimpers to the new collection.
        </p>
        <ConnectButton />

        {isConnected && (
          <>
            {error && (
              <div className="text-red-500 text-sm">
                Error: {error.message}
              </div>
            )}

            <TokenGrid
              tokenIds={tokenIds}
              isLoading={isLoading}
              selectedIds={selectedIds}
              onSelectionChange={setSelectedIds}
            />
          </>
        )}
      </main>
    </div>
  );
}
