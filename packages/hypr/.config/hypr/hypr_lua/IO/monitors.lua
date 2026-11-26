-- List outputs from left to right. Use an explicit mode and numeric scale
-- so IO/core.lua can calculate the horizontal positions.
return {
	{
		output = "desc:AOC 24B15H3 AP15536R03560",
		mode = "1920x1080@120",
		scale = 1,
		workspace = 3,
	},
	{
		output = "desc:AOC 24B15H3 AP15536R03516",
		mode = "1920x1080@120",
		scale = 1,
		workspace = 2,
	},
	{
		output = "desc:Shenzhen KTC Technology Group H27T22S 0x00000001",
		mode = "2560x1440@180.00",
		scale = 5 / 3,
		vrr = 1,
		bitdepth = 10,
		cm = "auto",
		workspace = 1,
		primary = true,
	},
}
