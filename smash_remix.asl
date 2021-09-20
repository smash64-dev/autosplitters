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
    settings.Add("forceDetectRom", false, "Force Smash Remix ROM");
    settings.SetToolTip("forceDetectRom", "Check this if you're using a ROM hack based on the Smash Remix ROM");

    settings.Add("allStarSplitAll", false, "All-Star Split Every Match");
    settings.SetToolTip("allStarSplitAll", "Check this if you want to split every match, instead when the match type changes");

    vars.versions = new Dictionary<int, Tuple<string, string>>() {
        { 10, Tuple.Create("1.0.0",  "FD0E716E-FB029C8E") },
        { 09, Tuple.Create("0.9.7",  "9D2B9C7F-6D90A8EF") },
        { 08, Tuple.Create("0.9.5b", "B9CDC5C3-0D2F4668") },
        { 07, Tuple.Create("0.9.5",  "B9B5831B-7F3DEBAF") },
        { 06, Tuple.Create("0.9.4",  "1B5AAD82-368B88C1") },
        { 05, Tuple.Create("0.9.3c", "40D195A0-8CA46F23") },
        { 04, Tuple.Create("0.9.3b", "00B61AB1-8B79A53C") },
        { 03, Tuple.Create("0.9.3",  "F1BB0C7C-77EA1DE8") },
        { 02, Tuple.Create("0.9.2",  "FA3AA571-673C45D2") },
        { 01, Tuple.Create("0.9",    "DEB992B2-55FC9187") },
    };

    vars.versionData = new Dictionary<string, Dictionary<string, int>>() {
        { "default-data", new Dictionary<string, int>() {
            // offsets
            { "lastScene",      0xA4AD2 },
            { "currentScene",   0xA4AD3 },  // + 0x01
            { "stage",          0xA4AE4 },  // + 0x12
            { "score",          0xA4AF0 },  // + 0x1E
            { "stageId",        0xA4B1A },  // + 0x48
            { "matchState",     0xA4B2A },  // + 0x58
            { "targets",        0x1313FF },
            { "platforms",      0x131403 },
            { "isLoading",      0x138F9C },
            { "bonusState",     0x18F1C2 },

            // constants
            { "asmSingles",     0x02 },
            { "asmDoubles",     0x04 },
            { "asmTriples",     0x05 },
            { "asmFinal",       0x01 },
            { "finalStage",     0x0D },     // round count
            { "gameSet",        0x06 },
            { "gameStart",      0x01 },
            { "stageRest",      0x8B },

            // features
            { "hasAllStar",     0x01 },
            { "hasCruelMan",    0x01 },
            { "hasMultiMan",    0x01 },
            { "hasRemix1P",     0x01 },

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
    vars.Debug = (Action<string>)((message) => {
        if (vars.debug) print("smash_remix: " + message);
    });

    vars.DeepCopy = (Func<Dictionary<string, int>, Dictionary<string, int>>)((dictToCopy) => {
        var newDict = new Dictionary<string, int>();
        foreach(var obj in dictToCopy) {
            newDict.Add(obj.Key, obj.Value);
        }
        return newDict;
    });

    vars.GetEmuOffset = (Func<int, int>)((offset) => {
        return current.emuBase + offset;
    });

    vars.GetEmuPtr = (Func<int, int>)((offset) => {
        uint emuPtr = memory.ReadValue<uint>(new IntPtr(current.emuBase) + offset);
        return vars.GetEmuOffset( (int)(emuPtr - 0x80000000) );
    });

    vars.GetRegionName = (Func<uint, uint, string>)((crc1, crc2) => {
        var crcStr = crc1.ToString("X") + "-" + crc2.ToString("X");

        // force to the latest publicly available version
        crcStr = settings["forceDetectRom"] ? "default-data" : crcStr;
        return crcStr;
    });

    vars.GetRomConstants = (Func<uint, uint, ExpandoObject>)((crc1, crc2) => {
        var crcStr = vars.GetRegionName(crc1, crc2);
        if (vars.versionData.ContainsKey(crcStr)) {
            var constants = vars.versionData[crcStr];

            dynamic obj = new ExpandoObject();
            // constants
            obj.asmSingles = constants["asmSingles"];
            obj.asmDoubles = constants["asmDoubles"];
            obj.asmTriples = constants["asmTriples"];
            obj.asmFinal = constants["asmFinal"];
            obj.finalStage = constants["finalStage"];
            obj.gameSet = constants["gameSet"];
            obj.gameStart = constants["gameStart"];
            obj.stageRest = constants["stageRest"];

            // features
            obj.hasAllStar = constants["hasAllStar"];
            obj.hasCruelMan = constants["hasCruelMan"];
            obj.hasMultiMan = constants["hasMultiMan"];
            obj.hasRemix1P = constants["hasRemix1P"];

            // scenes
            obj.gameMenu1p = constants["gameMenu1p"];
            obj.charSelect = constants["charSelect"];
            obj.bonus1Select = constants["bonus1Select"];
            obj.bonus2Select = constants["bonus2Select"];
            obj.bonusStage = constants["bonusStage"];

            return obj;
        } else {
            return new ExpandoObject();
        }
    });

    vars.GetRomState = (Func<uint, uint, MemoryWatcherList>)((crc1, crc2) => {
        var crcStr = vars.GetRegionName(crc1, crc2);
        if (vars.versionData.ContainsKey(crcStr)) {
            var offsets = vars.versionData[crcStr];

            return new MemoryWatcherList() {
                // menu addresses
                // TODO: figure out what isLoading actually is
                new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(offsets["currentScene"]))) { Name = "currentScene" },
                new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(offsets["isLoading"]))) { Name = "isLoading" },
                new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(offsets["lastScene"]))) { Name = "lastScene" },

                // 1p mode addresses
                new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(offsets["matchState"]))) { Name = "matchState" },
                new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(offsets["stage"]))) { Name = "stage" },
                new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(offsets["stageId"]))) { Name = "stageId" },
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

    // version specific features
    foreach (var version in vars.versions) {
        vars.versionData[version.Value.Item2] = vars.DeepCopy(vars.versionData["default-data"]);

        if (version.Key < 10) {
            vars.versionData[version.Value.Item2]["hasAllStar"] = 0x00;
        }

        if (version.Key < 9) {
            vars.versionData[version.Value.Item2]["hasRemix1P"] = 0x00;
        }

        if (version.Key < 6) {
            vars.versionData[version.Value.Item2]["hasCruelMan"] = 0x00;
            vars.versionData[version.Value.Item2]["hasMultiMan"] = 0x00;
        }
    }

    vars.allStarMode = false;
    vars.allStarProgress = 0;
    vars.allStarSplits = new List<int>();
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
        vars.Debug("starting 1P game");
        vars.classicMode = true;
        return true;
    }

    if (!vars.classicMode && vars.romState["currentScene"].Current == vars.romConst.bonusStage && vars.romState["bonusState"].Current == 1) {
        vars.Debug("starting bonus practice");
        return true;
    }
}

reset {
    if (vars.romState["currentScene"].Current == vars.romConst.gameMenu1p) {
        vars.Debug("resetting");
        vars.allStarMode = false;
        vars.allStarProgress = 0;
        vars.allStarSplits = new List<int>();
        vars.bossReady = false;
        vars.classicMode = false;
        return true;
    }

    if (!vars.classicMode) {
        if (vars.romState["currentScene"].Current == vars.romConst.bonusStage && vars.romState["bonusState"].Current == 0) {
            vars.Debug("resetting bonus practice");
            return true;
        }

        if (vars.romState["currentScene"].Current == vars.romConst.bonus1Select || vars.romState["currentScene"].Current == vars.romConst.bonus2Select) {
            vars.Debug("resetting bonus practice");
            return true;
        }
    }
}

split {
    if (vars.classicMode) {
        if (vars.romState["stage"].Current > vars.romState["stage"].Old) {
            vars.Debug("splitting 1P game (stage change)");
            return true;
        }

        // handle boss last hit
        if (vars.bossReady) {
            if (vars.romState["stage"].Current == vars.romConst.finalStage && vars.romState["matchState"].Current == vars.romConst.gameSet) {
                vars.Debug("splitting 1P game (last hit on boss)");
                return true;
            }
        }
    } else if (vars.allStarMode) {
        // moving from the rest stage into a new battle
        if (vars.romState["stageId"].Current == vars.romConst.stageRest && vars.romState["stage"].Current != vars.romState["stage"].Old) {
            if (vars.allStarProgress+1 <= vars.allStarSplits.Count && vars.romState["stage"].Current == vars.allStarSplits[vars.allStarProgress+1]) {
                vars.allStarProgress++;

                if (! settings["allStarSplitAll"]) {
                    vars.Debug("splitting all-star (new match style)");
                    return true;
                } else {
                    vars.Debug("not splitting, all-star (new match style)");
                }
            }

            // split every match change if set
            if (settings["allStarSplitAll"]) {
                vars.Debug("splitting all-star (new match)");
                return true;
            }
        }

        // handle last hit, progress
        if (vars.romState["stageId"].Current != vars.romConst.stageRest && vars.allStarProgress+1 == vars.allStarSplits.Count) {
            if (vars.romState["matchState"].Current == vars.romConst.gameSet) {
                vars.Debug("splitting all-star (last hit of match)");
                return true;
            }
        }
    } else {
        if (vars.romState["targets"].Current < vars.romState["targets"].Old) {
            vars.Debug("splitting bonus practice (targets)");
            return true;
        }

        if (vars.romState["platforms"].Current < vars.romState["platforms"].Old) {
            vars.Debug("splitting bonus practice (platforms)");
            return true;
        }
    }
}

update {
    // detect which rom is being played when the emulator starts it
    if (current.crc1 != old.crc1 || current.crc2 != old.crc2 || !vars.ready) {
        vars.romConst = vars.GetRomConstants(current.crc1, current.crc2);
        vars.romState = vars.GetRomState(current.crc1, current.crc2);

        vars.Debug("CRC detected (" + vars.GetRegionName(current.crc1, current.crc2) + ") is " + (vars.romState.Count == 0 ? "invalid" : "valid"));
        if (vars.romState.Count != 0) {
            vars.Debug("features available: (all-star: " + vars.romConst.hasAllStar + ", remix-1p: " + vars.romConst.hasRemix1P + ")");
        }
        vars.ready = true;
    }

    if (vars.romState.Count == 0) {
        return false;
    }

    vars.romState.UpdateAll(game);
    if (vars.classicMode) {
        // handle all star mode
        if (vars.romConst.hasAllStar == 1 && !vars.allStarMode && vars.romState["stageId"].Current == vars.romConst.stageRest) {
            vars.Debug("marking 1P game as all-star mode");
            vars.allStarMode = true;
            vars.allStarProgress = 0;
            vars.allStarSplits = new List<int>() { vars.romConst.asmSingles, vars.romConst.asmDoubles, vars.romConst.asmTriples, vars.romConst.asmFinal };
            vars.classicMode = false;
        }

        // handle final stage
        if (vars.romState["stage"].Current == vars.romConst.finalStage) {
            if (!vars.bossReady && vars.romState["matchState"].Current == vars.romConst.gameStart) {
                vars.Debug("marking 1P game final boss ready");
                vars.bossReady = true;
            }
        }
    }
}
