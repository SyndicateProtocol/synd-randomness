import { createPublicClient, http } from "viem"

export const syndicate = {
  id: 510,
  name: "Syndicate",
  network: "syndicate-network",
  nativeCurrency: {
    name: "Syndicate",
    symbol: "SYND",
    decimals: 18
  },
  rpcUrls: {
    default: {
      http: ["https://synd-mainnet.g.alchemy.com/public"]
    },
    public: {
      http: ["https://synd-mainnet.g.alchemy.com/public"]
    }
  },
  blockExplorers: {
    default: {
      name: "Syndicate Explorer",
      url: "https://explorer.syndicate.io/"
    }
  },
  testnet: true
}

export const syndicatePublicClient = createPublicClient({
  chain: syndicate,
  transport: http()
})
