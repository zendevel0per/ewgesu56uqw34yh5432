-- //////////////////////////////////////////////// ClearMemory //////////////////////////////////////////////

Config["ClearMemoryClient"] = {
	['ClearMemory'] = true , 		-- Client side for ClearMemory, recommended true
	['ClearMemoryTime'] = 30 , 		-- Units are minutes.
}

Config["ClearMemoryServer"] = {
	['ClearMemory'] = true , 		-- Server side for ClearMemory, recommended true
	['ClearMemoryTime'] = 30 , 		-- Units are minutes.
}

-- //////////////////////////////////////////////// DETECT CONVARNUM //////////////////////////////////////////////

Config["DROPTEXT"] = "Invalid settings detected." -->@ Player kick message if detected

Config["CONVARNUM"] = {
    ["profile_advGfxMaxLod"] = { -->@ Profile name set to be checked.
        ["Default"] = 0, -->@ Default value of this profile.
        ["Min"] = -5, -->@ How much lower must the profile value be to detect?
    }
}