import {
  LitActionResource,
  LitPKPResource,
  createSiweMessage,
  generateAuthSig
} from "@lit-protocol/auth-helpers"
import { LIT_ABILITY, LIT_NETWORK, LIT_RPC } from "@lit-protocol/constants"
import { LitNodeClient } from "@lit-protocol/lit-node-client"
import * as ethers from "ethers"
import { LocalStorage } from "node-localstorage"
//@ts-ignore
import type { Hex } from "viem"
import env from "../env"
import { litActionCode } from "./action"

export async function getLitRandomnessSequencerTransaction() {
  const client = new LitNodeClient({
    litNetwork: LIT_NETWORK.DatilDev,
    debug: false,
    alertWhenUnauthorized: true,
    storageProvider: {
      provider: new LocalStorage("./lit_storage.db")
    }
  })
  await client.connect()

  const ethersWallet = new ethers.Wallet(
    env.LIT_PRIVATE_KEY,
    new ethers.providers.JsonRpcProvider(LIT_RPC.CHRONICLE_YELLOWSTONE)
  )

  const sessionSigs = await client.getSessionSigs({
    chain: "ethereum",
    expiration: new Date(Date.now() + 1000 * 60 * 10).toISOString(), // 10 minutes
    resourceAbilityRequests: [
      {
        resource: new LitActionResource("*"),
        ability: LIT_ABILITY.LitActionExecution
      },
      {
        resource: new LitPKPResource("*"),
        ability: LIT_ABILITY.PKPSigning
      }
    ],
    authNeededCallback: async ({
      uri,
      expiration,
      resourceAbilityRequests
    }) => {
      const toSign = await createSiweMessage({
        uri,
        expiration,
        resources: resourceAbilityRequests,
        walletAddress: await ethersWallet.getAddress(),
        nonce: await client.getLatestBlockhash(),
        litNodeClient: client
      })

      return await generateAuthSig({
        signer: ethersWallet,
        toSign
      })
    }
  })
  const { success, response } = await client.executeJs({
    sessionSigs,
    code: litActionCode,
    jsParams: {
      RANDOMNESS_SEQUENCER_ADDRESS: env.RANDOMNESS_SEQUENCER_ADDRESS,
      APPCHAIN_RPC_URL: env.APPCHAIN_RPC_URL,
      APPCHAIN_CHAIN_ID: env.APPCHAIN_CHAIN_ID,
      SEQUENCING_CHAIN_RPC_URL: env.SEQUENCING_CHAIN_RPC_URL,
      SEQUENCING_CHAIN_ID: env.SEQUENCING_CHAIN_ID,
      PKP_PUBLIC_KEY: env.LIT_PKP_PUBLIC_KEY,
      DRAND_API_URL: env.DRAND_API_URL
    }
  })
  if (!success) {
    throw new Error("Failed to execute LIT action")
  }
  const { sequencerTransaction, randomnessTransaction, timestamp } = JSON.parse(response as string) as {
    sequencerTransaction: Hex,
    randomnessTransaction: Hex,
    timestamp: number
  }
  
  if (!sequencerTransaction) {
    throw new Error("No sequencer transaction found")
  }

  return {
    sequencerTransaction,
    randomnessTransaction,
    timestamp
  }
}
