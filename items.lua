local Items = {}

-- Basic item definitions
Items.database = {
    ["health_potion"] = {
        name = "Health Potion",
        type = "consumable",
        amount = 25,
        color = {1, 0, 0},
        size = 12,
    },

    ["mana_potion"] = {
        name = "Mana Potion",
        type = "consumable",
        amount = 20,
        color = {0, 0, 1},
        size = 12,
    },

    ["key"] = {
        name = "Dungeon Key",
        type = "key",
        color = {1, 1, 0},
        size = 10,
    },

    ["rare_shard"] = {
        name = "Ancient Shard",
        type = "rare",
        color = {0.6, 0.2, 1},
        size = 14,
    }
}

-- Create item instance
function Items:new(id, x, y)
    local data = self.database[id]
    assert(data, "Unknown item id: "..tostring(id))

    return {
        id = id,
        name = data.name,
        type = data.type,
        amount = data.amount,
        color = data.color,
        size = data.size,
        x = x,
        y = y,
        collected = false,
    }
end

return Items
