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
    settings.Add("forceAusRom", false, "Force AUS ROM");
    settings.SetToolTip("forceAusRom", "Check this if you're use a ROM hack based on the AUS ROM");

    settings.Add("forceEuRom", false, "Force EU ROM");
    settings.SetToolTip("forceEuRom", "Check this if you're use a ROM hack based on the EU ROM");

    settings.Add("forceJpRom", false, "Force JP ROM");
    settings.SetToolTip("forceJpRom", "Check this if you're use a ROM hack based on the JP ROM");

    settings.Add("forceNaRom", false, "Force NA ROM");
    settings.SetToolTip("forceNaRom", "Check this if you're use a ROM hack based on the NA ROM");

    vars.regionData = new Dictionary<string, Dictionary<string, int>>() {
        // Australia
        { "DD26FDA1-CB4A6BE3", new Dictionary<string, int>() {
            { "lastScene",      0xA5212 },
            { "currentScene",   0xA5213 },  // + 0x01
            { "stage",          0xA5224 },  // + 0x12
            { "score",          0xA5230 },  // + 0x1E
            { "matchState",     0xA526A },  // + 0x58
            { "isLoading",      0x1397BC },

            // constants
            { "finalBoss",      0x0C },     // master hand id
            { "finalStage",     0x0D },     // round count
            { "gameSet",        0x06 },
            { "gameStart",      0x01 },

            // scenes
            { "gameMenu1p",     0x09 },
            { "charSelect",     0x12 },
        } },
        // Europe
        { "93945F48-5C0F2E30", new Dictionary<string, int>() {
            { "lastScene",      0xAD332 },
            { "currentScene",   0xAD333 },  // + 0x01
            { "stage",          0xAD344 },  // + 0x12
            { "score",          0xAD350 },  // + 0x1E
            { "matchState",     0xAD38A },  // + 0x58
            { "isLoading",      0x141C9C },

            // constants
            { "finalBoss",      0x0C },     // master hand id
            { "finalStage",     0x0D },     // round count
            { "gameSet",        0x06 },
            { "gameStart",      0x01 },

            // scenes
            { "gameMenu1p",     0x09 },
            { "charSelect",     0x12 },
        } },
        // Japan
        { "67D20729-F696774C", new Dictionary<string, int>() {
            { "lastScene",      0xA2A92 },
            { "currentScene",   0xA2A93 },  // + 0x01
            { "stage",          0xA2AA4 },  // + 0x12
            { "score",          0xA2AB0 },  // + 0x1E
            { "matchState",     0xA2AEA },  // + 0x58
            { "isLoading",      0x136B9C },

            // constants
            { "finalBoss",      0x0C },     // master hand id
            { "finalStage",     0x0D },     // round count
            { "gameSet",        0x06 },
            { "gameStart",      0x01 },

            // scenes
            { "gameMenu1p",     0x08 },
            { "charSelect",     0x11 },
        } },
        // North America
        { "916B8B5B-780B85A4", new Dictionary<string, int>() {
            { "lastScene",      0xA4AD2 },
            { "currentScene",   0xA4AD3 },  // + 0x01
            { "stage",          0xA4AE4 },  // + 0x12
            { "score",          0xA4AF0 },  // + 0x1E
            { "matchState",     0xA4B2A },  // + 0x58
            { "isLoading",      0x138F9C },

            // constants
            { "finalBoss",      0x0C },     // master hand id
            { "finalStage",     0x0D },     // round count
            { "gameSet",        0x06 },
            { "gameStart",      0x01 },

            // scenes
            { "gameMenu1p",     0x08 },
            { "charSelect",     0x11 },
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

        crcStr = settings["forceAusRom"] ? "DD26FDA1-CB4A6BE3" : crcStr;
        crcStr = settings["forceEuRom"] ? "93945F48-5C0F2E30" : crcStr;
        crcStr = settings["forceJpRom"] ? "67D20729-F696774C" : crcStr;
        crcStr = settings["forceNaRom"] ? "916B8B5B-780B85A4" : crcStr;
        return crcStr;
    });

    vars.GetRomConstants = (Func<uint, uint, ExpandoObject>)((crc1, crc2) => {
        var crcStr = vars.GetRegionName(crc1, crc2);
        if (vars.regionData.ContainsKey(crcStr)) {
            var constants = vars.regionData[crcStr];

            dynamic obj = new ExpandoObject();
            obj.charSelect = constants["charSelect"];
            obj.finalBoss = constants["finalBoss"];
            obj.finalStage = constants["finalStage"];
            obj.gameMenu1p = constants["gameMenu1p"];
            obj.gameSet = constants["gameSet"];
            obj.gameStart = constants["gameStart"];

            return obj;
        } else {
            return new ExpandoObject();
        }
    });

    vars.GetRomState = (Func<uint, uint, MemoryWatcherList>)((crc1, crc2) => {
        var crcStr = vars.GetRegionName(crc1, crc2);
        if (vars.regionData.ContainsKey(crcStr)) {
            var offsets = vars.regionData[crcStr];

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
    vars.romConst = new ExpandoObject();
    vars.romState = new MemoryWatcherList();
}

start {
    vars.bossPort = -1;
    vars.bossReady = false;

    if (vars.romState["currentScene"].Current == vars.romConst.charSelect && vars.romState["isLoading"].Current == 1) {
        return true;
    }
}

reset {
    if (vars.romState["currentScene"].Current == vars.romConst.gameMenu1p) {
        vars.bossPort = -1;
        vars.bossReady = false;
        return true;
    }
}

split {
    if (vars.romState["stage"].Current > vars.romState["stage"].Old) {
        return true;
    }

    // handle boss last hit
    if (vars.bossReady) {
        if (vars.romState["stage"].Current == vars.romConst.finalStage && vars.romState["matchState"].Current == vars.romConst.gameSet) {
            return true;
        }
    }
}

update {
    // detect which rom is being played when the emulator starts it
    if (current.crc1 != old.crc1 || current.crc2 != old.crc2 || !vars.ready) {
        vars.romConst = vars.GetRomConstants(current.crc1, current.crc2);
        vars.romState = vars.GetRomState(current.crc1, current.crc2);
        vars.ready = true;
    }

    if (vars.romState.Count == 0) {
        return false;
    }

    vars.romState.UpdateAll(game);
    if (vars.romState["stage"].Current == vars.romConst.finalStage) {
        if (!vars.bossReady && vars.romState["matchState"].Current == vars.rom.Const.gameStart) {
            vars.bossReady = true;
        }
    }
}
