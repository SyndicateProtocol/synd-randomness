import { createConfig } from "ponder";

import { RandomnessSequencerAbi } from "./abis/RandomnessSequencerAbi";

const RPC_URL = process.env.RPC_URL;
const ADDRESS = process.env.ADDRESS as `0x${string}`;
const START_BLOCK = parseInt(process.env.START_BLOCK as string);

if (!RPC_URL || !ADDRESS || !START_BLOCK) {
  throw new Error("Missing environment variables");
}

export default createConfig({
  chains: {
    syndicate: {
      id: 510,
      rpc: RPC_URL,
    },
  },
  contracts: {
    RandomnessSequencer: {
      chain: "syndicate",
      abi: RandomnessSequencerAbi,
      address: ADDRESS,
      startBlock: START_BLOCK,
    },
  },
});
