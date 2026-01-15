extends Node

# Player data
var player_money: int = 500

var current_demand:  int = 0
var is_being_chased:  bool = false

signal chase_started(demand: int)
signal player_caught
