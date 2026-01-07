'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';

export default function Home() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-8 font-[family-name:var(--font-geist-sans)]">
      <main className="flex flex-col gap-8 items-center text-center">
        <h1 className="text-4xl font-bold">Chimpers Migration</h1>
        <p className="text-gray-600 dark:text-gray-400 max-w-md">
          Connect your wallet to migrate your Chimpers to the new collection.
        </p>
        <ConnectButton />
      </main>
    </div>
  );
}
