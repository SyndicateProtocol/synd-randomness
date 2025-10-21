import {
  AUTH_METHOD_SCOPE,
  AUTH_METHOD_TYPE,
  LIT_NETWORK,
  LIT_RPC
} from "@lit-protocol/constants"
import { LitContracts } from "@lit-protocol/contracts-sdk"
import { ethers } from "ethers"
// @ts-ignore
import Hash from "ipfs-only-hash"
import { litActionCode } from "./action"

const privateKey = process.env.LIT_PRIVATE_KEY as string
if (!privateKey) {
  throw new Error("LIT_PRIVATE_KEY is not set")
}

export async function mintPkp() {
  const ethersWallet = new ethers.Wallet(
    privateKey,
    new ethers.providers.JsonRpcProvider(LIT_RPC.CHRONICLE_YELLOWSTONE)
  )
  const litContracts = new LitContracts({
    signer: ethersWallet,
    network: LIT_NETWORK.DatilDev
  })
  await litContracts.connect()
  const mintCost = await litContracts.pkpNftContract.read.mintCost()
  const ipfsCidLocal = await Hash.of(litActionCode)
  // The context in which the lit action is run, could change its CID. 
  // It's possible you'll need to mint a new PKP and add a different CID here.
  // Without these permissions correct, the Lit Action will not be able to sign the transactions.
  console.log("minting PKP...")
  const cids = [
    ipfsCidLocal,
    // running via the indexer locally
    "QmWnZPUgqkeQAbMJA38HFNbAgLand9KzAHvbkw72eqzPXc"
  ]
  const txn =
    await litContracts.pkpHelperContract.write.mintNextAndAddAuthMethods(
      AUTH_METHOD_TYPE.LitAction,
      cids.map(() => AUTH_METHOD_TYPE.LitAction),
      cids.map((cid) => ethers.utils.base58.decode(cid)),
      cids.map(() => "0x"),
      cids.map(() => [AUTH_METHOD_SCOPE.SignAnything]),
      false,
      true,
      { value: mintCost, gasLimit: 4000000 }
    )
  const receipt = await txn.wait()
  const pkpId = receipt.logs[0]?.topics[1]
  if (!pkpId) {
    throw new Error("PKP ID not found")
  }
  const pkpPubkeyInfo = await litContracts.pubkeyRouterContract.read.pubkeys(
    ethers.BigNumber.from(pkpId)
  )
  const pkpPublicKey = pkpPubkeyInfo.pubkey
  const pkpEthAddress = ethers.utils.computeAddress(pkpPublicKey)
  const pkpInfo = {
    publicKey: pkpPublicKey,
    ethAddress: pkpEthAddress,
    tokenId: pkpId
  }
  console.log("PKP Info:", pkpInfo)
}

mintPkp()
  .then(() => {
    process.exit(0)
  })
  .catch((err) => {
    console.error(err)
    process.exit(1)
  })
