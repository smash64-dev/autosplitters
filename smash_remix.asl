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

    vars.regionData = new Dictionary<string, Dictionary<string, int>>() {
        // 1.0.0
        { "FD0E716E-FB029C8E", new Dictionary<string, int>() {
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
            { "finalStage",     0x0D },     // round count
            { "gameSet",        0x06 },
            { "gameStart",      0x01 },
            { "stageRest",      0x8B },

            // scenes
            { "gameMenu1p",     0x08 },
            { "charSelect",     0x11 },
            { "bonus1Select",   0x13 },     // break the targets
            { "bonus2Select",   0x14 },     // board the platforms
            { "bonusStage",     0x35 },
        } },
    };

    // older versions (some things may not work)
    vars.regionData["9D2B9C7F-6D90A8EF"] = vars.regionData["FD0E716E-FB029C8E"];    // 0.9.7
    vars.regionData["B9CDC5C3-0D2F4668"] = vars.regionData["FD0E716E-FB029C8E"];    // 0.9.5b
    vars.regionData["B9B5831B-7F3DEBAF"] = vars.regionData["FD0E716E-FB029C8E"];    // 0.9.5
    vars.regionData["1B5AAD82-368B88C1"] = vars.regionData["FD0E716E-FB029C8E"];    // 0.9.4
    vars.regionData["40D195A0-8CA46F23"] = vars.regionData["FD0E716E-FB029C8E"];    // 0.9.3c
    vars.regionData["00B61AB1-8B79A53C"] = vars.regionData["FD0E716E-FB029C8E"];    // 0.9.3b
    vars.regionData["F1BB0C7C-77EA1DE8"] = vars.regionData["FD0E716E-FB029C8E"];    // 0.9.3
    vars.regionData["FA3AA571-673C45D2"] = vars.regionData["FD0E716E-FB029C8E"];    // 0.9.2
    vars.regionData["DEB992B2-55FC9187"] = vars.regionData["FD0E716E-FB029C8E"];    // 0.9
}

init {
    vars.Debug = (Action<string>)((message) => {
        if (vars.debug) print("smash_remix: " + message);
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
        crcStr = settings["forceDetectRom"] ? "FD0E716E-FB029C8E" : crcStr;
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
        vars.ready = true;
    }

    if (vars.romState.Count == 0) {
        return false;
    }

    vars.romState.UpdateAll(game);
    if (vars.classicMode && vars.romState["stage"].Current == vars.romConst.finalStage) {
        if (!vars.bossReady && vars.romState["matchState"].Current == vars.romConst.gameStart) {
            vars.Debug("marking 1P game final boss ready");
            vars.bossReady = true;
        }
    }
}
