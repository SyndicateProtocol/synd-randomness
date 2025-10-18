import { createPublicClient, http } from "viem"

export const risa = {
  id: 51014,
  name: "Risa Testnet",
  network: "risa-testnet",
  nativeCurrency: {
    name: "Testnet Syndicate",
    symbol: "TestnetSYND",
    decimals: 18
  },
  rpcUrls: {
    default: {
      http: ["https://risa-testnet.g.alchemy.com/public"]
    },
    public: {
      http: ["https://risa-testnet.g.alchemy.com/public"]
    }
  },
  blockExplorers: {
    default: {
      name: "Risa Testnet Explorer",
      url: "https://risa-testnet.explorer.alchemy.com/"
    }
  },
  testnet: true
}

export const risaPublicClient = createPublicClient({
  chain: risa,
  transport: http()
})
