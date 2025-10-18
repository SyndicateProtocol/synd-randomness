import { createConfig } from "ponder";

import { RandomnessSequencerAbi } from "./abis/RandomnessSequencerAbi";
import env from "./env";

export default createConfig({
  chains: {
    syndicate: {
      id: env.SEQUENCING_CHAIN_ID,
      rpc: env.SEQUENCING_CHAIN_RPC_URL,
    },
  },
  contracts: {
    RandomnessSequencer: {
      chain: "syndicate",
      abi: RandomnessSequencerAbi,
      address: env.RANDOMNESS_SEQUENCER_ADDRESS,
      // we only want to inject randomness from the latest block
      startBlock: "latest",
    },
  },
});
