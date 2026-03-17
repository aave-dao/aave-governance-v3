-include .env

build :; forge build --sizes
test :; forge test -vvvv

# ---------------------------------------------- BASE SCRIPT CONFIGURATION ---------------------------------------------

BASE_LEDGER = --ledger --mnemonic-indexes $(MNEMONIC_INDEX) --sender $(LEDGER_SENDER)
BASE_KEY = --private-key ${PRIVATE_KEY}

custom_ethereum := --with-gas-price 5000000000 # 0.5 gwei
custom_polygon :=  --with-gas-price 170000000000 # 170 gwei
custom_polygon-testnet :=  --with-gas-price 20000000000 # 5 gwei
custom_avalanche := --with-gas-price 27000000000 # 27 gwei
custom_metis-testnet := --legacy --verifier-url https://goerli.explorer.metisdevops.link/api/
custom_metis := --verifier-url https://andromeda-explorer.metis.io/api/
custom_zksync := --zksync
custom_zksync-testnet := --legacy --zksync
custom_megaEth := --skip-simulation

# params:
#  1 - path/file_name
#  2 - network name
#  3 - script to call if not the same as network name (optional)
#  to define custom params per network add vars custom_network-name
#  to use ledger, set LEDGER=true to env
#  default to testnet deployment, to run production, set PROD=true to env
define deploy_single_fn
forge script \
 scripts/$(1).s.sol:$(if $(3),$(if $(PROD),$(3),$(3)_testnet),$(shell UP=$(if $(PROD),$(2),$(2)_testnet); echo $${UP} | perl -nE 'say ucfirst')) \
 --rpc-url $(if $(PROD),$(2),$(2)-testnet) --broadcast --verify --legacy -vvvv \
 $(if $(LEDGER),$(BASE_LEDGER),$(BASE_KEY)) \
 $(custom_$(if $(PROD),$(2),$(2)-testnet))

endef

define deploy_fn
 $(foreach network,$(2),$(call deploy_single_fn,$(1),$(network),$(3)))
endef

# ----------------------------------------------------------------------------------------------------------------------
# ----------------------------------------- DEPLOYMENT SCRIPTS ---------------------------------------------------------
deploy-initial:
	$(call deploy_fn,InitialDeployments,megaEth)

deploy-gov-power-strategy:
	$(call deploy_fn,Governance/Deploy_Gov_PowerStrategy,ethereum)

# Deploy Governance contracts
deploy-governance:
	$(call deploy_fn,Governance/Deploy_Governance,ethereum)

# Sets Governance as sender on CCF
set-gov-as-cff-sender:
	$(call deploy_fn,Governance/Set_Gov_as_CCF_Sender,ethereum)

## Deploy voting machine contracts
deploy-data-warehouse:
	$(call deploy_fn,VotingMachine/Deploy_DataWarehouse,ethereum avalanche polygon)

deploy-voting-strategy:
	$(call deploy_fn,VotingMachine/Deploy_VotingStrategy,ethereum avalanche polygon)

deploy-voting-machine:
	$(call deploy_fn,VotingMachine/Deploy_VotingMachine,avalanche)

set-vm-as-ccf-sender:
	$(call deploy_fn,VotingMachine/Set_VM_as_CCF_Sender,ethereum avalanche polygon)

deploy-executor-lvl1:
	$(call deploy_fn,Payloads/Deploy_ExecutorLvl1,megaEth)

deploy-executor-lvl2:
	$(call deploy_fn,Payloads/Deploy_ExecutorLvl2,ethereum)

## Deploy execution chain contracts
deploy-payloads-controller-chain:
	$(call deploy_fn,Payloads/Deploy_PayloadsController,megaEth)

## Deploy Governance Voting Portal
deploy-voting-portals:
	$(call deploy_fn,Governance/Deploy_VotingPortals,ethereum,Ethereum_Avalanche)
	$(call deploy_fn,Governance/Deploy_VotingPortals,ethereum,Ethereum_Ethereum)
	$(call deploy_fn,Governance/Deploy_VotingPortals,ethereum,Ethereum_Polygon)

set-vp-on-gov:
	$(call deploy_fn,Governance/Set_VotingPortals_on_Gov,ethereum)

set-vp-as_ccf-senders:
	$(call deploy_fn,Governance/Set_VP_as_CCF_Senders,ethereum)

## Deploy Contract Helpers
deploy-helper-contracts:
	$(call deploy_fn,Deploy_ContractHelpers,megaEth)

## Deployed permissioned payloads controller
deploy-permissioned-executor:
	$(call deploy_fn,Payloads/Deploy_PermissionedExecutor,ethereum)

deploy-permissioned-payloads-controller:
	$(call deploy_fn,Payloads/Deploy_PermissionedPayloadsController,ethereum)

deploy-granular-ppc-access-control:
	$(call deploy_fn,Payloads/Deploy_GranularPPCAccessControl,ethereum)

# -----------------------------------------------------
# ----------------- REPLACE VOTING MACHINE ------------
remove-vp-from-ccf-senders:
	$(call deploy_fn,Governance/Remove_VP_from_CCF_Senders,ethereum)

remove-voting-portal-from-gov:
	$(call deploy_fn,Governance/Remove_VotingPortal,ethereum)

remove-vm-from-ccf-senders-test:
	$(call deploy_fn,VotingMachine/Remove_Vm_from_CFF_Senders,ethereum avalanche)


# -----------------------------------------------------
# ----------------- HELPERS ------------
update-voting-config:
	$(call deploy_fn,helpers/GovernanceSetVotingConfig,ethereum)

deploy-payload:
	$(call deploy_fn,helpers/CreatePayload,zksync)

register-payload:
	$(call deploy_fn,helpers/RegisterPayload,zksync)

create-proposal:
	$(call deploy_fn,helpers/CreateProposal,ethereum)

update-pc-permissions:
	$(call deploy_fn,helpers/UpdatePCPermissions,megaEth)

update-executor-owner:
	$(call deploy_fn,helpers/UpdateExecutorOwner,megaEth)

deploy-merkle-payload-updates:
	$(call deploy_fn,GovernancePayloads/MerklePayloadUpdates,ethereum)
	$(call deploy_fn,GovernancePayloads/MerklePayloadUpdates,polygon)
	$(call deploy_fn,GovernancePayloads/MerklePayloadUpdates,avalanche)
