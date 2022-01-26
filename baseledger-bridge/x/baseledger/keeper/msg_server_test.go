package keeper_test

import (
	"context"
	"testing"

	keepertest "github.com/Baseledger/baseledger-bridge/testutil/keeper"
	"github.com/Baseledger/baseledger-bridge/x/baseledger/keeper"
	"github.com/Baseledger/baseledger-bridge/x/baseledger/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

func setupMsgServer(t testing.TB) (types.MsgServer, context.Context) {
	k, ctx := keepertest.BaseledgerKeeper(t)
	return keeper.NewMsgServerImpl(*k), sdk.WrapSDKContext(ctx)
}