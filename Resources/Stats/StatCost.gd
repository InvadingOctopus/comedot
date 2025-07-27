## A [Resource] representing a [Stat] cost, for [InteractionWithCostComponent] etc.

class_name StatCost
extends StatDependentResourceBase

# DESIGN: DUMBDOT: This has to be a separate class because [StatDependentResourceBase] is `@abstract`
# and dummy Godot won't let us use abstract classes as a variable's type, e.g. for `InteractionWithCostComponent.cost`
