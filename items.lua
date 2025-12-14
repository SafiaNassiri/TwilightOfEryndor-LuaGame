local Items = {}

-- Central item database
-- Each entry defines how an item behaves, looks, and what it does on pickup
Items.database = {
    ["health_potion"] = {
        name = "Health Potion",
        type = "consumable",
        amount = 25,                    -- HP restored
        color = {0.706, 0.322, 0.322},  -- #b45252 brick red
        size = 12,                      -- Draw radius / pickup size
        pickupMessage = "+25 HP restored",
        story = nil                     -- No lore text for common items
    },
    ["mana_potion"] = {
        name = "Mana Potion",
        type = "upgrade",
        amount = 0,                     -- Not used here (kept for consistency)
        speedIncrease = 20,             -- Boost player movement speed
        color = {0.761, 0.827, 0.408},  -- #c2d368 lime green
        size = 12,
        pickupMessage = "Speed increased!",
        story = nil
    },
    ["rare_shard"] = {
        name = "Ancient Shard",
        type = "rare",
        size = 14,
        color = {0.812, 0.541, 0.796},  -- #cf8acb pink/magenta
        pickupMessage = "Ancient Shard collected!",
        story = "The shard pulses with ancient power..."    -- Lore flavor text
    },
}

function Items:new(id, x, y)
    -- Look up item definition using its ID
    local data = self.database[id]

    -- Crash early if item ID doesn't exist
    assert(data, "Unknown item id: "..tostring(id))

    -- Create a live item instance using database values
    -- This separates static item data from runtime state
    return {
        id = id,
        x = x,
        y = y,
        size = data.size,                       -- Collision / draw size
        color = data.color,
        type = data.type,
        amount = data.amount,                   -- Value applied on pickup (if it has any)
        speedIncrease = data.speedIncrease,     -- Upgrade stat (if it has any)
        story = data.story,                     -- Optional lore text
        pickupMessage = data.pickupMessage      -- HUD feedback message
    }
end

return Items