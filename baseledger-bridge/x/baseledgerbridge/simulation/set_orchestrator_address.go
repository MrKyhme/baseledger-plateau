package simulation

import (
	"math/rand"

	"github.com/Baseledger/baseledger-bridge/x/baseledgerbridge/keeper"
	"github.com/Baseledger/baseledger-bridge/x/baseledgerbridge/types"
	"github.com/cosmos/cosmos-sdk/baseapp"
	sdk "github.com/cosmos/cosmos-sdk/types"
	simtypes "github.com/cosmos/cosmos-sdk/types/simulation"
)

func SimulateMsgSetOrchestratorAddress(
	ak types.AccountKeeper,
	bk types.BankKeeper,
	k keeper.Keeper,
) simtypes.Operation {
	return func(r *rand.Rand, app *baseapp.BaseApp, ctx sdk.Context, accs []simtypes.Account, chainID string,
	) (simtypes.OperationMsg, []simtypes.FutureOperation, error) {
		simAccount, _ := simtypes.RandomAcc(r, accs)
		msg := &types.MsgSetOrchestratorAddress{
			Validator: simAccount.Address.String(),
		}

		// TODO: Handling the SetOrchestratorAddress simulation

		return simtypes.NoOpMsg(types.ModuleName, msg.Type(), "SetOrchestratorAddress simulation not implemented"), nil, nil
	}
}
