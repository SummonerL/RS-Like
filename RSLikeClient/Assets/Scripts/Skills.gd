extends Node

# Main Skill class. Should define all properties and methods required for working with skills
class Skill:
	var name
	
	func _init(name: String):
		self.name = name
		
var skill_list = {}
		
func _ready():
	# Initialize our game skills
	var woodcutting = Skill.new("Woodcutting")
	
	skill_list[woodcutting.name] = woodcutting

const EXPERIENCE_TABLE = [
	0,     # Level 1
	100,   # Level 2
	400,   # Level 3
	900,   # Level 4
	1600,  # Level 5
	2500,  # Level 6
	3600,  # Level 7
	4900,  # Level 8
	6400,  # Level 9
	8100,  # Level 10
	10000, # Level 11
	12100, # Level 12
	14400, # Level 13
	16900, # Level 14
	19600, # Level 15
	22500, # Level 16
	25600, # Level 17
	28900, # Level 18
	32400, # Level 19
	36100, # Level 20
	40000, # Level 21
	44100, # Level 22
	48400, # Level 23
	52900, # Level 24
	57600, # Level 25
	62500, # Level 26
	67600, # Level 27
	72900, # Level 28
	78400, # Level 29
	84100, # Level 30
	90000, # Level 31
	96100, # Level 32
	102400, # Level 33
	108900, # Level 34
	115600, # Level 35
	122500, # Level 36
	129600, # Level 37
	136900, # Level 38
	144400, # Level 39
	152100, # Level 40
	160000, # Level 41
	168100, # Level 42
	176400, # Level 43
	184900, # Level 44
	193600, # Level 45
	202500, # Level 46
	211600, # Level 47
	220900, # Level 48
	230400, # Level 49
	240100  # Level 50
]
