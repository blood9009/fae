package servant

import (
	log "code.google.com/p/log4go"
	"github.com/funkygao/fae/servant/gen-go/fun/rpc"
)

func (this *FunServantImpl) Ping(ctx *rpc.ReqCtx) (r string, err error) {
	log.Debug("ping from %+v", *ctx)
	return "pong", nil
}
