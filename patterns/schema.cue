package patterns

import "strings"

#NonEmptyString: string & strings.MinRunes(1)
#NonEmptyStringList: [...#NonEmptyString] & [_, ...]

#CheckSet: {
	pass?: #NonEmptyStringList
	fail?: #NonEmptyStringList
}

#PatternEntry: {
	name:         #NonEmptyString
	summary:      #NonEmptyString
	demonstrates: #NonEmptyStringList

	canonical: _
	positive:  _
	negative:  _

	checks?: #CheckSet
	uses?:   #NonEmptyStringList
	notes?:  #NonEmptyStringList

	...
}

#PatternMap: {
	[string]: #PatternEntry
}

#Patterns: #PatternMap
