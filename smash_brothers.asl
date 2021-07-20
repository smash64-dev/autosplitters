state("Project64KSE") {
    int emuBase : "Project64KSE.exe", 0x9262C;
}

state("Project64KVE") {
    int emuBase : "Project64KVE.exe", 0x9262C;
}

init {
    // helper functions to access emulated memory
    vars.ReadEmuByte = (Func<int, byte>)((offset) => {
        return memory.ReadValue<byte>(new IntPtr(current.emuBase) + offset);
    });

    vars.ReadEmuInt = (Func<int, int>)((offset) => {
        return memory.ReadValue<int>(new IntPtr(current.emuBase) + offset);
    });

    vars.ReadEmuString = (Func<int, int, string>)((offset, length) => {
        return memory.ReadString(new IntPtr(current.emuBase) + offset, length);
    });

    vars.ReadEmuUint = (Func<int, uint>)((offset) => {
        return memory.ReadValue<uint>(new IntPtr(current.emuBase) + offset);
    });

    vars.GetEmuOffset = (Func<int, int>)((offset) => {
        return current.emuBase + offset;
    });

    vars.GetEmuPtr = (Func<int, int>)((offset) => {
        return vars.GetEmuOffset( (int)(vars.ReadEmuUint(offset) - 0x80000000) );
    });


    vars.gameState = new MemoryWatcherList() {
        // menu addresses; TODO: figure out what isLoading actually is
        new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(0xA4AD3))) { Name = "currentScene" },
        new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(0xA4AD2))) { Name = "lastScene" },
        new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(0x138F9C))) { Name = "isLoading" },

        // 1p mode addresses
        new MemoryWatcher<int>(new IntPtr(vars.GetEmuOffset(0xA4AF0))) { Name = "score" },
        new MemoryWatcher<byte>(new IntPtr(vars.GetEmuOffset(0xA4AE4))) { Name = "stage" },
        new MemoryWatcher<int>(new IntPtr(vars.GetEmuOffset(0x130D84))) { Name = "playerList" },
    };

    vars.masterHandPort = 0;
    vars.masterHandReady = false;
    vars.playerSize = 0x0B50;
    vars.playerState = new MemoryWatcherList();
}

start {
    // 17 == 1P Character Select Screen
    if (vars.gameState["currentScene"].Current == 17 && vars.gameState["isLoading"].Current == 1) {
        vars.masterHandPort = 0;
        vars.masterHandReady = false;
        return true;
    }
}

reset {
    // 8 == 1P Game Mode Menu
    if (vars.gameState["currentScene"].Current == 8) {
        vars.masterHandPort = 0;
        vars.masterHandReady = false;
        return true;
    }
}

split {
    if (vars.gameState["stage"].Current > vars.gameState["stage"].Old) {
        return true;
    }

    // handle master hand last hit
    if (vars.masterHandReady) {
        if (vars.gameState["stage"].Current == 13 && vars.playerState["p" + vars.masterHandPort + "Health"].Current >= 300) {
            vars.masterHandReady = false;
            return true;
        }
    }
}

update {
    vars.gameState.UpdateAll(game);
    vars.playerState.UpdateAll(game);

    // a new stage has loaded and player structs are in a different location, update
    if (vars.gameState["playerList"].Current != vars.gameState["playerList"].Old) {
        vars.masterHandReady = false;
        vars.playerState = new MemoryWatcherList();

        for (var i = 0; i < 4; i++) {
            var character = (vars.playerSize*i) + 0x08;
            var health = (vars.playerSize*i) + 0x2C;

            vars.playerState.Add(new MemoryWatcher<int>(new IntPtr(vars.GetEmuPtr(0x130D84) + character)) { Name = "p" + (i+1) + "Character" });
            vars.playerState.Add(new MemoryWatcher<int>(new IntPtr(vars.GetEmuPtr(0x130D84) + health)) { Name = "p" + (i+1) + "Health" });
        }
    } else {
        // detect the start of the master hand fight
        if (vars.gameState["stage"].Current == 13 && vars.gameState["currentScene"].Current == 1) {
            if (!vars.masterHandReady) {
                for (var i = 1; i < 5; i++) {
                    if (vars.playerState["p" + i + "Character"].Current == 12) {
                        vars.masterHandPort = i;
                    }
                }

                if (vars.masterHandPort > 0 && vars.playerState["p" + vars.masterHandPort + "Health"].Current == 0) {
                    vars.masterHandReady = true;
                }
            }

            // TODO: this should work, but there's probably a better way to do this
            if (vars.masterHandReady && vars.playerState["p" + vars.masterHandPort + "Health"].Current >= 350) {
                vars.masterHandReady = false;
            }
        }
    }
}
