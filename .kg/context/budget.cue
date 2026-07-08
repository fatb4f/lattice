package context

#TokenBudget: close({
	routePacketMaxBytes: int & >=0 & <=4096
	inlineEntityMax:     int & >=0 & <=3
	inlineResourceMax:   int & >=0 & <=8
	entityBodyInline:    false
	mcpPreferred:        true
})

defaultTokenBudget: #TokenBudget & {
	routePacketMaxBytes: 4096
	inlineEntityMax:     3
	inlineResourceMax:   8
	entityBodyInline:    false
	mcpPreferred:        true
}
