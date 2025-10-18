import { ponder } from "ponder:registry";

ponder.on("RandomnessSequencer:MempoolUpdated", (event) => {
  console.log("MempoolUpdated", event);
  console.log("Generating randomness...")
});
