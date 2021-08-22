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
    vars.gameSet = 0x06;
    vars.gameStart = 0x01;
    vars.finalBoss = 0xC;
    vars.finalStage = 0xD;

    vars.regionOffsets = new Dictionary<string, Dictionary<string, int>>() {
        // Japan
        { "67D20729-F696774C", new Dictionary<string, int>() {
            { "lastScene",      0xA2A92 },
            { "currentScene",   0xA2A93 },  // + 0x01
            { "stage",          0xA2AA4 },  // + 0x12
            { "score",          0xA2AB0 },  // + 0x1E
            { "matchState",     0xA2AEA },  // + 0x58
            { "isLoading",      0x136B9C },
        } },
        // North America
        { "916B8B5B-780B85A4", new Dictionary<string, int>() {
            { "lastScene",      0xA4AD2 },
            { "currentScene",   0xA4AD3 },  // + 0x01
            { "stage",          0xA4AE4 },  // + 0x12
            { "score",          0xA4AF0 },  // + 0x1E
            { "matchState",     0xA4B2A },  // + 0x58
            { "isLoading",      0x138F9C },
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
                // menu addresses
                // TODO: figure out what isLoading actually is
                new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(offsets["currentScene"]))) { Name = "currentScene" },
                new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(offsets["isLoading"]))) { Name = "isLoading" },
                new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(offsets["lastScene"]))) { Name = "lastScene" },

                // 1p mode addresses
                new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(offsets["matchState"]))) { Name = "matchState" },
                new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(offsets["stage"]))) { Name = "stage" },
                new MemoryWatcher<int>(new IntPtr(vars.GetEmuOffset(offsets["score"]))) { Name = "score" },
            };
        } else {
            return new MemoryWatcherList();
        }
    });

    vars.bossPort = -1;
    vars.bossReady = false;
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
        if (vars.romState["stage"].Current == vars.finalStage && vars.romState["matchState"].Current == vars.gameSet) {
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

    if (vars.romState["stage"].Current == vars.finalStage) {
        if (!vars.bossReady && vars.romState["matchState"].Current == vars.gameStart) {
            vars.bossReady = true;
        }
    }
}
