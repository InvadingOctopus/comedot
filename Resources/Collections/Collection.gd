## An abstract base class for [Resource]s which represent a collection or sequence of items.
## The items may be provided one at a time, or cycled through, or selected randomly and so on.
## A collection may be a finite "stack" that does not return further items once empty.
## This is different from a simple [Array] because a [Collection] subclass can be constructed as a standalone [Resource] `.tres` file in the Godot Editor and reused between multiple Components & scripts.
## NOTE: The exact behavior of each method and signal is up to the actual subclass implementation.
## TIP: Example Usage: Strings for conversations/dialogues, random numbers for "pre-rolled" dice, a predetermined list of loot, upgrades etc.
## WARNING: Multiple scripts accessing the same [Collection] subclass instance may modify/advance the same index or "cursor";
## each specific implementation and caller should handle or work around such conflicts.

@abstract class_name Collection
extends Resource


#region Abstract & Optional Virtual Methods
@warning_ignore_start("unused_parameter")

## Returns the current item from the collection or sequence, if any.
@abstract func getCurrentItem() -> Variant

## Returns the next item from the collection or sequence, if any.
@abstract func getNextItem() -> Variant

## Optional. Returns the previous item from the collection or sequence, if any.
## NOTE: Not guaranteed to emit the [signal willReturnFirstItem] or [signal willReturnFinalItem] signals.
func getPreviousItem() -> Variant:
	return null

## Optional. Returns a specific item from the collection or sequence, without affecting the "counter" index or "cursor" etc.
## May not be applicable if the data is an indeterminate stream etc.
func getItem(index: int) -> Variant:
	return null

## Optional. Returns the size of the collection or sequence, if applicable.
## Returns -1 if there is no determinate size, e.g. if the collection is a potentialy infinite stream.
func getSize() -> int:
	return -1

@warning_ignore_restore("unused_parameter")
#endregion


#region Signals
@warning_ignore_start("unused_signal")
signal willReturnFirstItem
signal willReturnFinalItem
@warning_ignore_restore("unused_signal")
#endregion
