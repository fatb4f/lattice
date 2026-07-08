package primitives

import "strings"

#NonEmptyString: string & strings.MinRunes(1)
#KebabID:        #NonEmptyString & =~"^[a-z0-9]+(-[a-z0-9]+)*$"

#GraphID:  #KebabID
#NodeID:   #KebabID
#EdgeID:   #KebabID
#ObjectID: #NonEmptyString
#RefName:  #NonEmptyString & !~"\\s"
#PathID:   #NonEmptyString

#NodeRefSet: {
	[#NodeID]: true
}

#EdgeRefSet: {
	[#EdgeID]: true
}

#SourceRefSet: {
	[#KebabID]: true
}
