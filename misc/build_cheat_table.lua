-- build_cheat_table.lua
-- quick utility to generate a cheat table in cheat engine

EMULATOR = {
    ["name"] = "Project64KSE.exe",
    ["offsets"] = {
        ["crc1"] = 0x90E50,
        ["crc2"] = 0x90E54,
        ["base"] = 0x9262C,
    },
}

REGIONS = {
    -- "DD26FDA1-CB4A6BE3"
    ["australia"] = {
        ["lastScene"]    = { 0xA5212, vtByte, true },
        ["currentScene"] = { 0xA5213, vtByte, true },
        ["stage"]        = { 0xA5224 },
        ["score"]        = { 0xA5230, vtDword },
        ["stageId"]      = { 0xA525A },
        ["matchState"]   = { 0xA526A },
        ["targets"]      = { 0x131C0F },
        ["platforms"]    = { 0x131C13 },
        ["isLoading"]    = { 0x1397BC },
        ["bonusState"]   = { 0x18FCB2 },
    },
    -- "93945F48-5C0F2E30"
    ["europe"] = {
        ["lastScene"]    = { 0xAD332, vtByte, true },
        ["currentScene"] = { 0xAD333, vtByte, true },
        ["stage"]        = { 0xAD344 },
        ["score"]        = { 0xAD350, vtDword },
        ["stageId"]      = { 0xAD37A },
        ["matchState"]   = { 0xAD38A },
        ["targets"]      = { 0x13A0EF },
        ["platforms"]    = { 0x13A0F3 },
        ["isLoading"]    = { 0x141C9C },
        ["bonusState"]   = { 0x197F22 },
    },
    -- "67D20729-F696774C"
    ["japan"] = {
        ["lastScene"]    = { 0xA2A92, vtByte, true },
        ["currentScene"] = { 0xA2A93, vtByte, true },
        ["stage"]        = { 0xA2AA4 },
        ["score"]        = { 0xA2AB0, vtDword },
        ["stageId"]      = { 0xA2ADA },
        ["matchState"]   = { 0xA2AEA },
        ["targets"]      = { 0x12EF8F },
        ["platforms"]    = { 0x12EF93 },
        ["isLoading"]    = { 0x136B9C },
        ["bonusState"]   = { 0x18CA82 },
    },
    -- "916B8B5B-780B85A4"
    ["north america"] = {
        ["lastScene"]    = { 0xA4AD2, vtByte, true },
        ["currentScene"] = { 0xA4AD3, vtByte, true },
        ["stage"]        = { 0xA4AE4 },
        ["score"]        = { 0xA4AF0, vtDword },
        ["stageId"]      = { 0xA4B1A },
        ["matchState"]   = { 0xA4B2A },
        ["targets"]      = { 0x1313FF },
        ["platforms"]    = { 0x131403 },
        ["isLoading"]    = { 0x138F9C },
        ["bonusState"]   = { 0x18F1C2 },
    },
}

-- add_to_group <str>, <str>, { <int>, <int>, <bool> }, <memrec>
function add_to_group(addr, desc, data, group)
    local record = LIST.createMemoryRecord()
    record.setAddress(addr)
    record.setDescription(desc)

    if (data[1]) then
        record.setOffsetCount(1)
        record.setOffset(0, data[1])
    end

    record.Type = data[2] and data[2] or vtByte
    record.ShowAsHex = data[3] and data[3] or false

    record.appendToEntry(group)
end

LIST = getAddressList()

-- create a basic emulator group
local group = LIST.createMemoryRecord()
group.setDescription("emulator")
for offset, data in pairs(EMULATOR["offsets"]) do
    local address = string.format("%s+%x", EMULATOR["name"], data)
    add_to_group(address, offset, {false, vtDword, true}, group)
end

-- add region specific offsets from emulator
local emu_base = string.format("%s+%x", EMULATOR["name"], EMULATOR["offsets"]["base"])
for region, offsets in pairs(REGIONS) do
    group = LIST.createMemoryRecord()
    group.setDescription(region)

    local offset_keys = {}
    for key in pairs(offsets) do table.insert(offset_keys, key) end
    table.sort(offset_keys)

    for _, offset in ipairs(offset_keys) do
        add_to_group(emu_base, offset, offsets[offset], group)
    end
end
