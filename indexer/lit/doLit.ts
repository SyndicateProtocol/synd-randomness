import { getLitRandomnessSequencerTransaction } from "./getLitRandomnessSequencerTransaction"

const sequencerTransaction = await getLitRandomnessSequencerTransaction()
console.log("sequencerTransaction", sequencerTransaction)
process.exit(0)
