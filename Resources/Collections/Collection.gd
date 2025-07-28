## An abstract base class for [Resource]s which represent a collection or sequence of items.
## The items may be provided one at a time, or cycled through, or completely random and so on.
## A collection may be a finite "stack" that does not return further items once empty.
## This is different from a simple Array because a [Collection] can be constructed as a standalone file in the Godot Editor and reused between multiple Components & scripts,
## and each item of the [Collection] may be determined programmatically.
## Examples: Strings for conversations/dialogues, random numbers for "pre-rolled" dice, a predetermined list of loot, upgrades etc.
## @experimental

@abstract class_name Collection
extends Resource


#region Abstract Methods
@warning_ignore_start("unused_parameter")

## Returns the current item from the collection or sequence, if any.
@abstract func getCurrentItem() -> Variant

## Returns the next item from the collection or sequence, if any.
@abstract func getNextItem() -> Variant

## Optional. Returns the previous item from the collection or sequence, if any.
## NOTE: Not guaranteed to emit the [signal willReturnFirstItem] or [signal willReturnFinalItem] signals.
func getPreviousItem() -> Variant:
	return null

## Optional. Returns a specific item from the collection or sequence, without affecting the "counter" index.
## May not be applicable if the collection is random or "lazy".
func getItem(index: int) -> Variant:
	return null

## Optional. Returns the size of the collection or sequence, if applicable.
## Returns -1 if there is no determinate size, e.g. if the collection is random, "lazy", or infinite.
func getSize() -> int:
	return -1

#endregion


#region Signals
@warning_ignore_start("unused_signal")

signal willReturnFirstItem
signal willReturnFinalItem
#endregion
