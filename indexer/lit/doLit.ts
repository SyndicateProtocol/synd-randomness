import { getLitRandomnessSequencerTransaction } from "./getLitRandomnessSequencerTransaction"

const bundlerTransaction = await getLitRandomnessSequencerTransaction()
console.log("bundlerTransaction", bundlerTransaction)
process.exit(0)
