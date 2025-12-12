local Items = {}

Items.database = {
    ["health_potion"] = {
        name = "Health Potion",
        type = "consumable",
        amount = 25,
        color = {1,0,0}, -- red
        size = 12
    },
    ["mana_potion"] = {
        name = "Mana Potion",
        type = "consumable",
        amount = 2,
        color = {0,0,1}, -- blue
        size = 12
    },
    ["rare_shard"] = {
        name = "Ancient Shard",
        type = "rare",
        size = 14,
        color = {0.6,0.2,1}
    },
}

function Items:new(id, x, y)
    local data = self.database[id]
    assert(data, "Unknown item id: "..tostring(id))
    return {
        id = id,
        x = x,
        y = y,
        size = data.size,
        color = data.color,
        type = data.type,
        amount = data.amount
    }
end

return Items
