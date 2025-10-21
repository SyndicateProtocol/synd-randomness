const env = {
  LIT_PRIVATE_KEY: process.env.LIT_PRIVATE_KEY as string,
  LIT_PKP_PUBLIC_KEY: process.env.LIT_PKP_PUBLIC_KEY as string,
  APPCHAIN_RPC_URL: process.env.APPCHAIN_RPC_URL as string,
  APPCHAIN_CHAIN_ID: parseInt(process.env.APPCHAIN_CHAIN_ID as string),
  SEQUENCING_CHAIN_RPC_URL: process.env.SEQUENCING_CHAIN_RPC_URL as string,
  SEQUENCING_CHAIN_ID: parseInt(process.env.SEQUENCING_CHAIN_ID as string),
  RANDOMNESS_SEQUENCER_CONTRACT_ADDRESS: process.env.RANDOMNESS_SEQUENCER_CONTRACT_ADDRESS as `0x${string}`,
  RANDOM_CONTRACT_ADDRESS: process.env.RANDOM_CONTRACT_ADDRESS as `0x${string}`,
  DRAND_API_URL: process.env.DRAND_API_URL as string,
  LIT_DEBUG: process.env?.LIT_DEBUG === "true",
}

for (const [key, value] of Object.entries(env)) {
  if (value === undefined || value === null) {
    throw new Error(`Environment variable ${key} is not set`);
  }
}

export default env;
