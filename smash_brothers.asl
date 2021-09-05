state("Project64KSE") {
    uint crc1 : "Project64KSE.exe", 0x90E50;
    uint crc2 : "Project64KSE.exe", 0x90E54;
    int emuBase : "Project64KSE.exe", 0x9262C;
}

state("Project64KVE") {
    uint crc1 : "Project64KVE.exe", 0x90E50;
    uint crc2 : "Project64KVE.exe", 0x90E54;
    int emuBase : "Project64KVE.exe", 0x9262C;
}

startup {
    settings.Add("forceAusRom", false, "Force Australia ROM");
    settings.SetToolTip("forceAusRom", "Check this if you're using a ROM hack based on the Australia ROM");

    settings.Add("forceEuRom", false, "Force Europe ROM");
    settings.SetToolTip("forceEuRom", "Check this if you're using a ROM hack based on the Europe ROM");

    settings.Add("forceJpRom", false, "Force Japan ROM");
    settings.SetToolTip("forceJpRom", "Check this if you're using a ROM hack based on the Japan ROM");

    settings.Add("forceNaRom", false, "Force North America ROM");
    settings.SetToolTip("forceNaRom", "Check this if you're using a ROM hack based on the North America ROM");

    vars.regionData = new Dictionary<string, Dictionary<string, int>>() {
        // Australia
        { "DD26FDA1-CB4A6BE3", new Dictionary<string, int>() {
            // offsets
            { "lastScene",      0xA5212 },
            { "currentScene",   0xA5213 },  // + 0x01
            { "stage",          0xA5224 },  // + 0x12
            { "score",          0xA5230 },  // + 0x1E
            { "matchState",     0xA526A },  // + 0x58
            { "targets",        0x131C0F },
            { "platforms",      0x131C13 },
            { "isLoading",      0x1397BC },
            { "bonusState",     0x18FCB2 },

            // constants
            { "finalBoss",      0x0C },     // master hand id
            { "finalStage",     0x0D },     // round count
            { "gameSet",        0x06 },
            { "gameStart",      0x01 },

            // scenes
            { "gameMenu1p",     0x09 },
            { "charSelect",     0x12 },
            { "bonus1Select",   0x14 },     // break the targets
            { "bonus2Select",   0x15 },     // board the platforms
            { "bonusStage",     0x36 },
        } },
        // Europe
        { "93945F48-5C0F2E30", new Dictionary<string, int>() {
            // offsets
            { "lastScene",      0xAD332 },
            { "currentScene",   0xAD333 },  // + 0x01
            { "stage",          0xAD344 },  // + 0x12
            { "score",          0xAD350 },  // + 0x1E
            { "matchState",     0xAD38A },  // + 0x58
            { "targets",        0x13A0EF },
            { "platforms",      0x13A0F3 },
            { "isLoading",      0x141C9C },
            { "bonusState",     0x197F22 },

            // constants
            { "finalBoss",      0x0C },     // master hand id
            { "finalStage",     0x0D },     // round count
            { "gameSet",        0x06 },
            { "gameStart",      0x01 },

            // scenes
            { "gameMenu1p",     0x09 },
            { "charSelect",     0x12 },
            { "bonus1Select",   0x14 },     // break the targets
            { "bonus2Select",   0x15 },     // board the platforms
            { "bonusStage",     0x36 },
        } },
        // Japan
        { "67D20729-F696774C", new Dictionary<string, int>() {
            // offsets
            { "lastScene",      0xA2A92 },
            { "currentScene",   0xA2A93 },  // + 0x01
            { "stage",          0xA2AA4 },  // + 0x12
            { "score",          0xA2AB0 },  // + 0x1E
            { "matchState",     0xA2AEA },  // + 0x58
            { "targets",        0x12EF8F },
            { "platforms",      0x12EF93 },
            { "isLoading",      0x136B9C },
            { "bonusState",     0x18CA82 },

            // constants
            { "finalBoss",      0x0C },     // master hand id
            { "finalStage",     0x0D },     // round count
            { "gameSet",        0x06 },
            { "gameStart",      0x01 },

            // scenes
            { "gameMenu1p",     0x08 },
            { "charSelect",     0x11 },
            { "bonus1Select",   0x13 },     // break the targets
            { "bonus2Select",   0x14 },     // board the platforms
            { "bonusStage",     0x34 },
        } },
        // North America
        { "916B8B5B-780B85A4", new Dictionary<string, int>() {
            // offsets
            { "lastScene",      0xA4AD2 },
            { "currentScene",   0xA4AD3 },  // + 0x01
            { "stage",          0xA4AE4 },  // + 0x12
            { "score",          0xA4AF0 },  // + 0x1E
            { "matchState",     0xA4B2A },  // + 0x58
            { "targets",        0x1313FF },
            { "platforms",      0x131403 },
            { "isLoading",      0x138F9C },
            { "bonusState",     0x18F1C2 },

            // constants
            { "finalBoss",      0x0C },     // master hand id
            { "finalStage",     0x0D },     // round count
            { "gameSet",        0x06 },
            { "gameStart",      0x01 },

            // scenes
            { "gameMenu1p",     0x08 },
            { "charSelect",     0x11 },
            { "bonus1Select",   0x13 },     // break the targets
            { "bonus2Select",   0x14 },     // board the platforms
            { "bonusStage",     0x35 },
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
            obj.bonusStage = constants["bonusStage"];
            obj.bonus1Select = constants["bonus1Select"];
            obj.bonus2Select = constants["bonus2Select"];
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

                // bonus mode addresses
                new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(offsets["targets"]))) { Name = "targets" },
                new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(offsets["platforms"]))) { Name = "platforms" },
                new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(offsets["bonusState"]))) { Name = "bonusState" },
            };
        } else {
            return new MemoryWatcherList();
        }
    });

    vars.bossReady = false;
    vars.classicMode = false;
    vars.debug = true;
    vars.ready = false;
    vars.romConst = new ExpandoObject();
    vars.romState = new MemoryWatcherList();
}

start {
    vars.bossReady = false;

    if (vars.romState["currentScene"].Current == vars.romConst.charSelect && vars.romState["isLoading"].Current == 1) {
        if (vars.debug) print("smash_brothers 1p mode: starting");
        vars.classicMode = true;
        return true;
    }

    if (!vars.classicMode && vars.romState["currentScene"].Current == vars.romConst.bonusStage && vars.romState["bonusState"].Current == 1) {
        if (vars.debug) print("smash_brothers bonus mode: starting");
        return true;
    }
}

reset {
    if (vars.romState["currentScene"].Current == vars.romConst.gameMenu1p) {
        if (vars.debug) print("smash_brothers: resetting");

        vars.bossReady = false;
        vars.classicMode = false;
        return true;
    }

    if (!vars.classicMode) {
        if (vars.romState["currentScene"].Current == vars.romConst.bonusStage && vars.romState["bonusState"].Current == 0) {
            if (vars.debug) print("smash_brothers bonus mode: resetting");
            return true;
        }

        if (vars.romState["currentScene"].Current == vars.romConst.bonus1Select || vars.romState["currentScene"].Current == vars.romConst.bonus2Select) {
            if (vars.debug) print("smash_brothers bonus mode: resetting");
            return true;
        }
    }

}

split {
    if (vars.classicMode) {
        if (vars.romState["stage"].Current > vars.romState["stage"].Old) {
            if (vars.debug) print("smash_brothers 1p mode: splitting (stage change)");
            return true;
        }

        // handle boss last hit
        if (vars.bossReady) {
            if (vars.romState["stage"].Current == vars.romConst.finalStage && vars.romState["matchState"].Current == vars.romConst.gameSet) {
                if (vars.debug) print("smash_brothers 1p mode: splitting (last hit)");
                return true;
            }
        }
    } else {
        if (vars.romState["targets"].Current < vars.romState["targets"].Old) {
            if (vars.debug) print("smash_brothers bonus mode: splitting (targets)");
            return true;
        }

        if (vars.romState["platforms"].Current < vars.romState["platforms"].Old) {
            if (vars.debug) print("smash_brothers bonus mode: splitting (platforms)");
            return true;
        }
    }
}

update {
    // detect which rom is being played when the emulator starts it
    if (current.crc1 != old.crc1 || current.crc2 != old.crc2 || !vars.ready) {
        vars.romConst = vars.GetRomConstants(current.crc1, current.crc2);
        vars.romState = vars.GetRomState(current.crc1, current.crc2);

        if (vars.debug) {
            var crcStr = vars.GetRegionName(current.crc1, current.crc2);
            print("smash_brothers: crc detected (" + crcStr + ") is " + (vars.romState.Count == 0 ? "invalid" : "valid"));
        }
        vars.ready = true;
    }

    if (vars.romState.Count == 0) {
        return false;
    }

    vars.romState.UpdateAll(game);

    if (vars.classicMode && vars.romState["stage"].Current == vars.romConst.finalStage) {
        if (!vars.bossReady && vars.romState["matchState"].Current == vars.romConst.gameStart) {
            if (vars.debug) print("smash_brothers 1p mode: final boss is ready");
            vars.bossReady = true;
        }
    }
}
