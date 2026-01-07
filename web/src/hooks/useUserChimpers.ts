import { useState, useEffect, useCallback } from 'react';
import { Alchemy, Network } from 'alchemy-sdk';

const OLD_CHIMPERS_ADDRESS = '0x80336Ad7A747236ef41F47ed2C7641828a480BAA';

const alchemy = new Alchemy({
  apiKey: process.env.NEXT_PUBLIC_ALCHEMY_API_KEY || 'demo',
  network: Network.ETH_MAINNET,
});

interface UseUserChimpersResult {
  tokenIds: bigint[];
  isLoading: boolean;
  error: Error | null;
  refetch: () => Promise<void>;
}

export function useUserChimpers(address: string | undefined): UseUserChimpersResult {
  const [tokenIds, setTokenIds] = useState<bigint[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const fetchTokens = useCallback(async () => {
    if (!address) {
      setTokenIds([]);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const nfts = await alchemy.nft.getNftsForOwner(address, {
        contractAddresses: [OLD_CHIMPERS_ADDRESS],
      });

      const ids = nfts.ownedNfts.map((nft) => BigInt(nft.tokenId));
      setTokenIds(ids);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch tokens'));
      setTokenIds([]);
    } finally {
      setIsLoading(false);
    }
  }, [address]);

  useEffect(() => {
    fetchTokens();
  }, [fetchTokens]);

  return {
    tokenIds,
    isLoading,
    error,
    refetch: fetchTokens,
  };
}
