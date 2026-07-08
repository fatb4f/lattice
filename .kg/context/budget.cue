package context

#TokenBudget: close({
	routePacketMaxBytes: int & >=0 & <=4096
	inlineEntityMax:     int & >=0 & <=3
	inlineResourceMax:   int & >=0 & <=8
	maxAutoReadBytes:    int & >=0 & <=4096
	allowExpensiveReads: bool
	entityBodyInline:    false
	mcpPreferred:        true
})

defaultTokenBudget: #TokenBudget & {
	routePacketMaxBytes: 4096
	inlineEntityMax:     3
	inlineResourceMax:   8
	maxAutoReadBytes:    4096
	allowExpensiveReads: false
	entityBodyInline:    false
	mcpPreferred:        true
}
