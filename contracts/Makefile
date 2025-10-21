include .env
export

.PHONY: deploy-sequencer deploy-random deploy-all deploy-do-something-with-random allowlist-function get-functions allowlist-randomness-sequencer add-randomness-sequencer-admin add-random-admin

deploy-sequencer:
	forge script script/Deploy.s.sol:DeployRandomnessSequencer --rpc-url $(SEQUENCING_CHAIN_RPC_URL) --broadcast

deploy-random:
	forge script script/Deploy.s.sol:DeployRandom --rpc-url $(APPCHAIN_RPC_URL) --broadcast

deploy-do-something-with-random:
	forge script script/Deploy.s.sol:DeployDoSomethingWithRandom --rpc-url $(APPCHAIN_RPC_URL) --broadcast

allowlist-function:
	forge script script/Config.s.sol:AddFunctionToRandomnessSequencerAllowlist --rpc-url $(SEQUENCING_CHAIN_RPC_URL) --broadcast

get-functions:
	cast call $(RANDOMNESS_SEQUENCER_CONTRACT_ADDRESS) "getAllowlistedFunctions()((address,bytes4)[])" --rpc-url $(SEQUENCING_CHAIN_RPC_URL)

allowlist-randomness-sequencer:
	forge script script/Config.s.sol:AllowlistRandomnessSequencerOnSyndicateSequencingChain --rpc-url $(SEQUENCING_CHAIN_RPC_URL) --broadcast

add-randomness-sequencer-admin:
	forge script script/Config.s.sol:AddRandomAdminToRandomnessSequencer --rpc-url $(SEQUENCING_CHAIN_RPC_URL) --broadcast

add-random-admin:
	forge script script/Config.s.sol:AddRandomAdminToRandom --rpc-url $(APPCHAIN_RPC_URL) --broadcast
