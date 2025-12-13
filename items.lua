local Items = {}

Items.database = {
    ["health_potion"] = {
        name = "Health Potion",
        type = "consumable",
        amount = 25,
        color = {0, 1, 1},  -- Cyan
        size = 12,
        pickupMessage = "+25 HP restored",
        story = nil
    },
    ["mana_potion"] = {
        name = "Mana Potion",
        type = "consumable",
        amount = 15,  -- Changed: now heals 15 HP instead of speed boost
        speedIncrease = 0,  -- Removed speed boost
        color = {0, 0.5, 1},  -- Blue
        size = 12,
        pickupMessage = "+15 HP restored",
        story = nil
    },
    ["rare_shard"] = {
        name = "Ancient Shard",
        type = "rare",
        size = 14,
        color = {0.6, 0.2, 1},  -- Purple
        pickupMessage = "Ancient Shard collected!",
        story = "The shard pulses with ancient power..."
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
        amount = data.amount,
        speedIncrease = data.speedIncrease,
        story = data.story,
        pickupMessage = data.pickupMessage
    }
end

return Items