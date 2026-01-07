'use client';

import { useState } from 'react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount } from 'wagmi';
import { useUserChimpers } from '@/hooks/useUserChimpers';
import { TokenGrid } from '@/components/TokenGrid';
import { ApprovalButton } from '@/components/ApprovalButton';
import { MigrateButton } from '@/components/MigrateButton';

export default function Home() {
  const { address, isConnected } = useAccount();
  const { tokenIds, isLoading, error, refetch } = useUserChimpers(address);
  const [selectedIds, setSelectedIds] = useState<Set<bigint>>(new Set());

  const handleMigrationSuccess = () => {
    setSelectedIds(new Set());
    refetch();
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-gray-100 dark:from-gray-900 dark:to-gray-950 font-[family-name:var(--font-geist-sans)]">
      {/* Header */}
      <header className="w-full border-b border-gray-200 dark:border-gray-800 bg-white/50 dark:bg-gray-900/50 backdrop-blur-sm">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
          <h1 className="text-xl sm:text-2xl font-bold text-gray-900 dark:text-white">
            Chimpers Migration
          </h1>
          <ConnectButton />
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8 sm:py-12">
        {!isConnected ? (
          <div className="flex flex-col items-center justify-center min-h-[60vh] text-center">
            <div className="p-8 sm:p-12 bg-white dark:bg-gray-800 rounded-2xl shadow-lg max-w-md">
              <h2 className="text-2xl sm:text-3xl font-bold mb-4 text-gray-900 dark:text-white">
                Welcome to the Migration
              </h2>
              <p className="text-gray-600 dark:text-gray-400 mb-6">
                Connect your wallet to migrate your Chimpers to the new collection with enhanced features.
              </p>
              <ConnectButton />
            </div>
          </div>
        ) : (
          <div className="space-y-8">
            {error && (
              <div className="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-red-600 dark:text-red-400 text-sm">
                Error: {error.message}
              </div>
            )}

            {/* Token Selection Section */}
            <section className="bg-white dark:bg-gray-800 rounded-2xl shadow-lg p-4 sm:p-6 lg:p-8">
              <h2 className="text-lg sm:text-xl font-semibold mb-4 text-gray-900 dark:text-white">
                Select Chimpers to Migrate
              </h2>
              <TokenGrid
                tokenIds={tokenIds}
                isLoading={isLoading}
                selectedIds={selectedIds}
                onSelectionChange={setSelectedIds}
              />
            </section>

            {/* Action Section */}
            {tokenIds.length > 0 && (
              <section className="bg-white dark:bg-gray-800 rounded-2xl shadow-lg p-4 sm:p-6 lg:p-8">
                <h2 className="text-lg sm:text-xl font-semibold mb-4 text-gray-900 dark:text-white">
                  Migration Actions
                </h2>
                <div className="flex flex-col sm:flex-row gap-4 items-center justify-center">
                  <ApprovalButton ownerAddress={address} />
                  <MigrateButton
                    selectedIds={selectedIds}
                    ownerAddress={address}
                    onSuccess={handleMigrationSuccess}
                  />
                </div>
              </section>
            )}
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="w-full border-t border-gray-200 dark:border-gray-800 mt-auto">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-6 text-center text-sm text-gray-500 dark:text-gray-400">
          Chimpers Migration Portal
        </div>
      </footer>
    </div>
  );
}
