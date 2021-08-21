state("Project64KSE") {
    uint crc1 : "Project64KSE.exe", 0x90E50;
    uint crc2 : "Project64KSE.exe", 0x90E54;
    int emuBase : "Project64KSE.exe", 0x9262C;
}

state("Project64KVE") {
    uint crc1 : "Project64KSE.exe", 0x90E50;
    uint crc2 : "Project64KSE.exe", 0x90E54;
    int emuBase : "Project64KVE.exe", 0x9262C;
}

startup {
    settings.Add("forceNaRom", false, "Force NA ROM");
    settings.SetToolTip("forceNaRom", "Check this if you're use a ROM hack based on the NA ROM");

    settings.Add("forceJpRom", false, "Force JP ROM");
    settings.SetToolTip("forceJpRom", "Check this if you're use a ROM hack based on the JP ROM");

    // constants
    vars.characterSelect = 0x11;
    vars.gameMenu1p = 0x08;
    vars.finalBoss = 0xC;
    vars.finalDamage = 300;
    vars.finalStage = 0xD;
    vars.maxPorts = 4;
    vars.playerSize = 0x0B50;

    vars.playerOffsets = new Dictionary<string, int>() {
        { "character",  0x08 },
        { "health",     0x2C },
    };

    vars.regionOffsets = new Dictionary<string, Dictionary<string, int>>() {
        // Japan
        { "67D20729-F696774C", new Dictionary<string, int>() {
            { "currentScene",   0xA2A93 },
            { "isLoading",      0x136B9C },
            { "lastScene",      0xA2A92 },
            { "playerList",     0x12E914 },
            { "score",          0xA2AB0 },
            { "stage",          0xA2AA4 },
        } },
        // North America
        { "916B8B5B-780B85A4", new Dictionary<string, int>() {
            { "currentScene",   0xA4AD3 },
            { "isLoading",      0x138F9C },
            { "lastScene",      0xA4AD2 },
            { "playerList",     0x130D84 },
            { "score",          0xA4AF0 },
            { "stage",          0xA4AE4 },
        } },
    };
}

init {
    vars.GetEmuOffset = (Func<int, int>)((offset) => {
        return current.emuBase + offset;
    });

    vars.GetEmuPtr = (Func<int, int>)((offset) => {
        uint emuPtr = memory.ReadValue<uint>(new IntPtr(current.emuBase) + offset);
        return vars.GetEmuOffset( (int)(emuPtr - 0x80000000) );
    });

    vars.GetPlayerState = (Func<uint, uint, int, MemoryWatcherList>)((crc1, crc2, port) => {
        var crcStr = vars.GetRegionName(crc1, crc2);
        if (vars.regionOffsets.ContainsKey(crcStr)) {
            var playerList = vars.regionOffsets[crcStr]["playerList"];

            var watcherList = new MemoryWatcherList();
            foreach(KeyValuePair<string, int> item in vars.playerOffsets) {
                // everything we need is an int, for now; you may need to refactor this later
                var offset = (vars.playerSize * port) + item.Value;
                watcherList.Add(new MemoryWatcher<int>(new IntPtr(vars.GetEmuPtr(playerList) + offset)) { Name = item.Key });
            }

            return watcherList;
        } else {
            return new MemoryWatcherList();
        }
    });

    vars.GetRegionName = (Func<uint, uint, string>)((crc1, crc2) => {
        var crcStr = crc1.ToString("X") + "-" + crc2.ToString("X");
        crcStr = settings["forceJpRom"] ? "67D20729-F696774C" : crcStr;
        crcStr = settings["forceNaRom"] ? "916B8B5B-780B85A4" : crcStr;
        return crcStr;
    });

    vars.GetRomState = (Func<uint, uint, MemoryWatcherList>)((crc1, crc2) => {
        var crcStr = vars.GetRegionName(crc1, crc2);
        if (vars.regionOffsets.ContainsKey(crcStr)) {
            var offsets = vars.regionOffsets[crcStr];

            return new MemoryWatcherList() {
                // menu addresses; TODO: figure out what isLoading actually is
                new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(offsets["currentScene"]))) { Name = "currentScene" },
                new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(offsets["isLoading"]))) { Name = "isLoading" },
                new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(offsets["lastScene"]))) { Name = "lastScene" },

                // 1p mode addresses
                new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(offsets["stage"]))) { Name = "stage" },
                new MemoryWatcher<int>(new IntPtr(vars.GetEmuOffset(offsets["playerList"]))) { Name = "playerList" },
                new MemoryWatcher<int>(new IntPtr(vars.GetEmuOffset(offsets["score"]))) { Name = "score" },
            };
        } else {
            return new MemoryWatcherList();
        }
    });

    vars.bossPort = -1;
    vars.bossReady = false;
    vars.playerState = new List<MemoryWatcherList>(vars.maxPorts);
    vars.ready = false;
    vars.romState = new MemoryWatcherList();
}

start {
    vars.bossPort = -1;
    vars.bossReady = false;

    if (vars.romState["currentScene"].Current == vars.characterSelect && vars.romState["isLoading"].Current == 1) {
        return true;
    }
}

reset {
    if (vars.romState["currentScene"].Current == vars.gameMenu1p) {
        vars.bossPort = -1;
        vars.bossReady = false;
        return true;
    }
}

split {
    if (vars.romState["stage"].Current > vars.romState["stage"].Old) {
        return true;
    }

    // handle master hand last hit
    if (vars.bossReady) {
        if (vars.romState["stage"].Current == vars.finalStage && vars.playerState[vars.bossPort]["health"].Current >= vars.finalDamage) {
            return true;
        }
    }
}

update {
    // detect which rom is being played when the emulator starts it
    if (current.crc1 != old.crc1 || current.crc2 != old.crc2 || !vars.ready) {
        vars.romState = vars.GetRomState(current.crc1, current.crc2);
        vars.ready = true;
    }

    if (vars.romState.Count == 0) {
        return false;
    }

    vars.romState.UpdateAll(game);
    for (var port = 0; port < vars.playerState.Count; port++) {
        if (vars.playerState[port] is MemoryWatcherList) {
            vars.playerState[port].UpdateAll(game);
        }
    }

    // a new stage has loaded and player structs are in a different location, update
    if (vars.romState["playerList"].Current != vars.romState["playerList"].Old) {
        vars.bossReady = false;
        vars.playerState = new List<MemoryWatcherList>(vars.maxPorts);

        for (var port = 0; port < vars.maxPorts; port++) {
            vars.playerState.Insert(port, vars.GetPlayerState(current.crc1, current.crc2, port));
        }
    } else {
        // detect the start of the master hand fight
        if (vars.romState["stage"].Current == vars.finalStage && vars.romState["currentScene"].Current == 1) {
            if (!vars.bossReady) {
                for (var port = 0; port < vars.playerState.Count; port++) {
                    if (vars.playerState[port]["character"].Current == vars.finalBoss) {
                        vars.bossPort = port;
                    }
                }

                if (vars.bossPort >= 0 && vars.playerState[vars.bossPort]["health"].Current == 0) {
                    vars.bossReady = true;
                }
            }

            // TODO: this should work, but there's probably a better way to do this
            if (vars.bossReady && vars.playerState[vars.bossPort]["health"].Current >= vars.finalDamage + 50) {
                vars.bossReady = false;
            }
        }
    }
}
