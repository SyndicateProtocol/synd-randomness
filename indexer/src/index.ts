import { ponder } from "ponder:registry";
import { risaPublicClient } from "../chain/risa";
import { getLitRandomnessSequencerTransaction } from "../lit/getLitRandomnessSequencerTransaction";

ponder.on("RandomnessSequencer:MempoolUpdated", async (event) => {
  console.log("Generating randomness...")
  try {
    const { sequencerTransaction } = await getLitRandomnessSequencerTransaction()
    const hash = await risaPublicClient.sendRawTransaction({
      serializedTransaction: sequencerTransaction,
    })
    console.log("Randomness injection sent to sequencer:", hash)
  } catch (error) {
    console.error("Error sending transaction", error)
  }
});
