--[[

	NOTICE TO NEW ASPIRIUM USERS.
	
	IF YOU KNOW BASICALLY NOTHING ABOUT LUA, OR ARE NOT SURE ABOUT HOW TO CONFIGURE THE SYSTEM, PLEASE SKIP TO LINE 26 AND START READING.
	DO NOT MAKE SUPPORT TICKETS ABOUT ERRORS WITH THIS MODULE

]]--




--[[

	A message to all Aspirium users.
	Please give the people below the credit they deserve. This project would not be possible without the maintainers of Adonis.
	
	Sceleratis / Davey_Bones
	Kohltastrophe (Scripth)
	einsteinK
	Rerumu (Shining_Diamando)
	Cald_fan
	joritichip
	Coasterteam
	
	@GitHub MudockYatho
	@GitHub TheCakeChicken
	@GitHub NNickey
	@GitHub ItsGJK
	@GitHub Kan18
	@GitHub Brandon-Beck
	@GitHub GeneralScripter
	@GitHub moo1210
	@GitHub kent911t
	@GitHub crywink
	@GitHub jaydensar
	@GitHub ccuser44
	@GitHub Awesomewebm
	@GitHub TheLegendarySpark
	@GitHub DaEnder
	@GitHub pbstFusion
	@GitHub policetonyR
	@GitHub enescglyn
	@GitHub EpicFazbear
	@GitHub p3tray
	@GitHub okgabe
	@GitHub fxeP1
	@GitHub optimisticside
	@GitHub NeoInversion
	@GitHub LolloDev5123
	@GitHub happyman090
	@GitHub Expertcoderz
	@GitHub GalacticInspired
	@GitHub flgx16
	@GitHub DrewBokman
	@GitHub Kw6m
	@GitHub chexburger
	@GitHub TjeerdoBoy112
	@GitHub Jack5079
	@GitHub Bulldo344
	@GitHub evanultra01
	@GitHub SlipperySpelunky
	@GitHub c6lvnss
	@GitHub alau740
	
]]--

------------------------------------------
--- 	 Scroll down for settings  	   ---
---    Do not alter the lines below    ---
------------------------------------------

local Settings = {}
local Descriptions = {}

--[[

	--------------
	-- Settings --
	--------------

			-- Basic Lua Info --
			
			This is only here to help you when editing settings so you understand how they work
				and don't break something.

			Anything that looks like `Settings.Setting = {}` (primarily with the {}) is called a table.
			Tables contain things; like the Lua version of a box.
				An example of a table would be `setting = {"John","Mary","Bill"}`
				
			You can have tables inside of tables, such in the case of setting = { Group = { ID = 1 } }
			Just like real boxes, tables can contain pretty much anything including other tables, except there's no real size limit.
			
			Anything that looks like "Bob" is what's known as a string. Strings
			are basically plain text; setting = "Bob" would be correct however
			setting = Bob would not; because if it's not surrounded by quotes Lua will think
			that Bob is a variable; Quotes indicate something is a string and therefor not a variable/number/code
			
			Numbers do not use quotes. setting = 56
			
			This gray block of text you are reading is called a comment. It's like a message
			from the programmer to anyone who reads their stuff. Anything in a comment will
			not be seen by Lua.

			Incase you don't know what Lua is; Lua is the scripting language Roblox uses...
			so every script you see (such as this one) and pretty much any code on Roblox is
			written in Lua.
			
			
			
			
			-- Specific Settings --
			
			If you see something like "Format: 'Username:UserId'" it means that anything you put
			in that table must follow one of the formats next to Format:
			
			For instance if I wanted to give admin to a player using their username, userid, a group they are in
			or an item they own I would do the following with the Settings.Admins table:

			The format for the Admins' table's entries is "Username"; or "Username:UserId"; or UserId; or "Group:GroupId:GroupRank" or "Item:ItemID"
			This means that if I want to admin Bobjenkins123 who has a userId of 1234567, is in
			group "BobFans" (group ID 7463213) under the rank number 234, or owns the item belonging to ID 1237465
			I can do any of the following:

								Username           Username:UserId     UserId   Group:GroupId:Rank	 Item:ItemId
									V                     V               V				V                 V
			Settings.Admins = {"Bobjenkins123","Bobjenkins123:1234567",1234567,"Group:7463213:234","Item:1237465"}
			
			**TO THOSE WHO ARE CONFUSED IF THE GROUP OR ITEM CONFIGURATION OPTION DOES NOT WORK:**
				The "Group:" or "Item:" in the string is a prefix, it tells the system that the data it is reading,
				Is a group ID + group rank, or an ItemId.
				**THIS IS ONLY FOR GROUPS AND ITEMS**
				Usernames and UserIds do not support any prefixes.
				
			If I wanted to make it so rank 134 in group 1029934 and BobJenkins123 had mod admin I would do
				Settings.Moderators = {"Group:1029943:134","BobJenkins123"}
				
				
				
				
			-- Admins --
			
				Settings.Moderators = {"Sceleratis";"BobJenkins:1237123";1237666;"Group:181:255";"Item:1234567"}
					This will make the person with the username Sceleratis, or the name BobJenkins, or the ID 1237123 OR 123766,
					   or is in group 181 in the rank 255, or owns the item belonging to the ID 1234567 a moderator
					   
					If I wanted to give the rank 121 in group 181 Owner admin I would do:
					   settings.HeadAdmins = {"Group:181:121"}
					   See? Not so hard is it?

					If I wanted to add group 181 and all ranks in it to the ;slock whitelist I would do;
						settings.Whitelist = {"Group:181";}

					I can do the above if I wanted to give everyone in a group admin for any of the other admin tables
					
			
			
			
			-- Command Permissions --
			
				You can set the permission level for specific commands using Settings.CommandPermissions
				If I wanted to make it so only HeadAdmins+ can use ;ff player then I would do:

					Settings.CommandPermissions = {";ff:HeadAdmins"}

					ff is the Command ";ff scel" and HeadAdmins is the new level

					Built-In Permissions Levels:
						Players    - 0
						Moderators - 30
						Admins     - 50
						HeadAdmins - 70
						Creators   - 90

					Note that when changing command permissions you MUST include the prefix;
					So if you change the prefix to $ you would need to do $ff instead of ;ff
					
			
			
			
			-- Trello --
			
				The Trello abilities of the script allow you to manage lists and permissions via
				a Trello board; The following will guide you through the process of setting up a board;

					1. Sign up for an account at http://trello.com
					2. Create a new board
						http://prntscr.com/b9xljn
						http://prntscr.com/b9xm53
					3. Get the board ID;
						http://prntscr.com/b9xngo
					4. Add your board ID to Settings.HTTP.Trello.Boards
					5. Set Settings.HTTP.Trello.Enabled to true
					6. Congrats! The board is ready to be used;
					7. Create a list and add cards to it;
						http://prntscr.com/b9xswk

					- You can view lists in-game using ;viewlist ListNameHere
					
				Lists:
					Moderators			- Card Format: Same as Settings.Moderators
					Admins				- Card Format: Same as Settings.Admins
					HeadAdmins				- Card Format: Same as Settings.HeadAdmins
					Creators			- Card Format: Same as Settings.Creators
					Banlist				- Card Format: Same as Settings.Banned
					Mutelist			- Card Format: Same as Settings.Muted
					Blacklist			- Card Format: Same as Settings.Blacklist
					Whitelist			- Card Format: Same as Settings.Whitelist
					Permissions			- Card Format: Same as Settings.CommandPermissions
					Music				- Card Format: SongName:AudioID
			
			Card format refers to how card **names** should look
			
			
			
			
			
			**IF YOU ARE USING INTERNAL DATASTORAGE, MAKE SURE TO SET Settings.DataStore.Key TO SOMETHING ABSOLUTELY RANDOM.
]]--
    local ServerStorage = game:GetService("ServerStorage")

	Settings.ModuleId = ServerStorage.MainModule

	Settings.DataStore = {
		Method = "Internal", --// Usable Methods: Internal; None; Web (MUST HAVE WEBPANEL ACCOUNT + WEBPANEL ENABLED)
		Database = "Aspirium_1", --// Only enabled if using Internal data storage
		Key = "CHANGE_ME"
	}

	Settings.Roles = {
		Moderators = {
			Level = 30,
			Users = {
				--// Users must follow the user format above. (Lines 77 - 104)
			}
		},
		
		Admins = {
			Level = 50,
			Users = {
				--// Users must follow the user format above. (Lines 77 - 104)
			}
		},
		
		HeadAdmins = {
			Level = 70,
			Users = {
				--// Users must follow the user format above. (Lines 77 - 104)
			}
		},
		
		Creators = {
			Level = 90,
			Users = {
				--// Users must follow the user format above. (Lines 77 - 104)
			}
		}
	}

	Settings.CommandPermissions = {
		--// Command Permissions must follow the command permissions format above. (Lines 109 - 126)
	}

	Settings.Banned = { --// Banned users / groups from the game.
		--// Bans must follow the user format above. (Lines 77 - 104)
	}

	Settings.Muted = { --// Auto-Muted users / groups (revokes the ability to chat)
		--// Mutes must follow the user format above. (Lines 77 - 104)
	}

	Settings.Blacklist = { --// Users who are blacklisted from receiving administrative privileges.
		--// Blacklists must follow the user format above. (Lines 77 - 104)
	}

	Settings.Whitelist = { --// Users who are whitelisted (Bypass server lock / whitelist restrictions)
		Enabled = false,
		Users = {
			--// Whitelists must follow the user format above. (Lines 77 - 104)\	
		}
	}

	Settings.EventCommands = { --// Commands to run on each pre-defined event
		OnServerStart = {},
		OnPlayerJoin = {},
		OnPlayerSpawn = {}
	}

	Settings.AntiExploit = { --// Anti-Exploit configuration; It is not recomennded to mess around with this
		NotifyLevel = 30, --// The minimum admin level that will be notified when players are detected exploiting
		Checks = {
			AntiNil = true,
			AntiSpeed = true,
			AntiNoClip = true,
			AntiGui = true,
			AntiBuildingTools = false,
			AntiSave = false
		}
	}

	Settings.Miscellaneous = { --// Random general settings used for minor things
		Prefix = ";", --// The prefix for running admin commands (;smite, ;to, ;bring, ;kill)
		PlayerPrefix = "!", --// The prefix for running player commands (!help, !donate)
		SpecialPrefix = "", --// Used for modifiers such as "all", "me", and "others" (If changed to ! you would run ;kill !me, or ;kill !all)
		SplitKey = " ", --// The space in ;smite all (If changed to / the command would run as ;smite/all, or ;bring/all)
		BatchKey = "|", --// The character used to detect multiple commands in one message (Such as ;fling all | ;smite all | ;respawn all)
		ConsoleKeyCode = Enum.KeyCode.Quote, --// The default button used to open the console
		ConsoleIsAdminOnly = false, --// Determines if normal players are able to open the console (Rank Level 0)
		
		FunCommands = true, --// Determimnes if commands marked as `Fun = true` are runnable
		PlayerCommands = true, --// Determines if commands prefixed with `!` are runnable
		CrossServerCommands = true, --// Determines if cross-server commands are runnable
		ChatCommands = true, --// Determines if commands can be run in chat, or console only
		CreatorPowers = true, --// Determines if I (Sky, the Aspirium developer) has access to creator-admin (mainly for debugging.)
		ModeratorPowers = false, --// Determines if global Aspirium moderators (Users ranked as moderators or admins in the Aspirium group)
								 --// have Admin
		CodeExecution = true, --// Determines if the `;script` command is enabled to run code on the server / client.
		
		BanMessage = {
			
		},
		
		LockMessage = {
			
		},
		
		SystemTitle = "Aspirium System", --// The title that will be shown in ;sm
		
		MaxLogs = 5000, --// The maximum amount of logs the system will store, before deleting the oldest.
		AdminNotifications = true,
		SongHint = true,
		TopBarShift = false,
		
		AutoClean = {
			Enabled = false,
			Delay = 60
		},
		
		AutoBackup = false,
		
		CustomChat = false,
		CustomPlayerList = false,
		
		Console = true,
		
		HelpSystem = true,
		InformationButton = {
			Enabled = true,
			Image = "rbxassetid://357249130"
		},
		
		ToolStorage = ServerStorage
	}

	Settings.HTTP = { --// All HTTP-Related settings, such as Trello settings and Web Panel Settings
		Trello = {
			Enabled = false, --// Determines if trello functionality is enabled.
			RefreshDelay = 60, --// Determines how often (in seconds) the server will fetch trello data.
			Boards = {}, --// All boards to scan when running trello checks
			AppKey = "";              -- Your Trello AppKey						  	Link: https://trello.com/app-key
			Token = "";               -- Trello token (DON'T SHARE WITH ANYONE!)    Link: https://trello.com/1/connect?name=Aspirium&response_type=token&expires=never&scope=read,write&key=YOUR_APP_KEY_HERE
		},
		
		WebPanel = {
			Enabled = false,
			Key = "",
			SyncRate = "Auto" --// Sync Rate auto will update Web Panel data as updates are received (Almost immediate)
				--// If Sync Rate is a number, it will fetch Web Panel data every X amount of seconds
				--// Please follow the Aspirium Web Panel RateLimit documentation
		}
	}

	Settings.GameAPI = { --// Allows other scripts within your game to access Aspirium functions if given proper access
		Enabled = true,
		Access = {
			Enabled = false,
			Permissions = "r", --// Set to "rw" to allow read + write; "r" only allows reading the requested data, not changing it
			Key = ""
		},
		
		AllowedCalls = {
			Client = false;				-- Allow access to the Client (not recommended)
			Settings = false;			-- Allow access to settings (not recommended)
			DataStore = false;			-- Allow access to the DataStore (not recommended)
			Core = false;				-- Allow access to the script's core table (REALLY not recommended)
			Service = false;			-- Allow access to the script's service metatable
			Remote = false;				-- Communication table
			HTTP = false; 				-- HTTP related things like Trello functions
			AntiExploit = false;		-- Anti-Exploit table
			Logs = false;
			UI = false;					-- Client UI table
			Admin = false;				-- Admin related functions
			Functions = false;			-- Functions table (contains functions used by the script that don't have a subcategory)
			Variables = true;			-- Variables table
			API_Specific = true;		-- API Specific functions
		}
	}

	---------------------
	-- End of Settings --
	---------------------

    Descriptions.ModuleId = "The Module Id the system should load."

    Descriptions.DataStore = {
        Method = "Methods: Internal; None; Web (MUST HAVE WEBPANEL ACCOUNT + WEBPANEL ENABLED)",
        Database = "Only enabled if using Internal data storage",
        Key = "The DataStore encryption key."
    }

    Descriptions.Roles = {
        
    }


return {Settings = Settings, Descriptions = Descriptions}