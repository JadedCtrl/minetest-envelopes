-- For translation
local S = minetest.get_translator("envelopes")

minetest.register_craftitem("envelopes:envelope_blank", {
    description = S("Blank Envelope"),
    inventory_image = "envelopes_envelope_blank.png",
    on_use = function(itemstack, user, pointed_thing)
        minetest.show_formspec(user:get_player_name(), "envelopes:input", 
            "size[5.5,5.5]" ..
            "field[2,0.5;3.5,1;addressee;" .. S("Addressee") .. ";]" ..
            "label[0,0;" .. S("Write a letter") .. "]" ..
            "textarea[0.5,1.5;5,3;text;" .. S("Text") .. ";]" ..
            "field[3,4.8;2.5,1;attn;" .. S("Attn. (Optional)") .. ";]" ..
            "button_exit[0.25,4.5;2,1;exit;" .. S("Seal") .. "]")
        return itemstack
    end
})

minetest.register_craftitem("envelopes:envelope_sealed", {
    description = S("Sealed Envelope"),
    inventory_image = "envelopes_envelope_sealed.png",
    stack_max = 1,
    groups = {not_in_creative_inventory = 1},
    on_use = function(itemstack, user, pointed_thing)
        meta = itemstack:get_meta()
        if user:get_player_name() == meta:get_string("receiver") then
            open_env = ItemStack("envelopes:envelope_opened")
            open_meta = open_env:get_meta()
            open_meta:set_string("sender", meta:get_string("sender"))
            open_meta:set_string("receiver", meta:get_string("receiver"))
            open_meta:set_string("text", meta:get_string("text"))
            local desc = S("Opened Envelope") .. "\n" ..
                S("To: @1", meta:get_string("receiver")) .. "\n" ..
                S("From: @1", meta:get_string("sender"))
            open_meta:set_string("description", desc)
            if meta:get_string("attn") ~= "" then
                open_meta:set_string("attn", meta:get_string("attn"))
                desc = desc .. "\n" .. S("Attn: @1", meta:get_string("attn"))
                open_meta:set_string("description", desc)
            end
            return open_env
        end
        minetest.chat_send_player(user:get_player_name(), S("The seal can only be opened by the addressee!"))
        return itemstack
    end
})

minetest.register_craftitem("envelopes:envelope_opened", {
    description = S("Opened Envelope"),
    inventory_image = "envelopes_envelope_opened.png",
    stack_max = 1,
    groups = {not_in_creative_inventory = 1},
    on_use = function(itemstack, user, pointed_thing)
        local meta = itemstack:get_meta()
        local sender = meta:get_string("sender")
        local receiver = meta:get_string("receiver")
        local text = meta:get_string("text")
        local attn = meta:get_string("attn") or ""
        local form = 
            "size[5,5]" ..
            "label[0,0;" .. S("A letter from @1 to @2", sender, receiver)
        if attn ~= "" then
            form = form .. "\n" .. S("Attn: @1", attn)
        end
        form = form .. "\n" .. text .. "]" .. "button_exit[0,4;2,1;exit;" .. S("Close") .. "]"
        minetest.show_formspec(user:get_player_name(), "envelope:display", form)
    end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "envelopes:input" or not minetest.is_player(player) then
        return false
    end

    if fields.addressee == "" or fields.addressee == nil or fields.text == "" or fields.text == nil then
        minetest.chat_send_player(player:get_player_name(), S("Please fill out all required fields."))
        return true
    end

    local inv = player:get_inventory()
    local letter = ItemStack('envelopes:envelope_sealed')
    local blank = ItemStack('envelopes:envelope_blank')
    local meta = letter:get_meta()

    meta:set_string("sender", player:get_player_name())
    meta:set_string("receiver", fields.addressee)
    meta:set_string("text", fields.text)

    local desc = S("Sealed Envelope") .. "\n" ..
        S("To: @1", fields.addressee) .. "\n" ..
        S("From: @1", player:get_player_name())
    meta:set_string("description", desc)

    if fields.attn ~= "" then
        meta:set_string("attn", fields.attn)
        desc = desc .. "\n" .. S("Attn: @1", fields.attn)
        meta:set_string("description", desc)
    end

    if inv:room_for_item("main", letter) and inv:contains_item("main", blank) then
        inv:add_item("main", letter)
        inv:remove_item("main", blank)
    else
        minetest.chat_send_player(player:get_player_name(), S("Unable to create letter! Check your inventory space."))
    end

    return true
end)

minetest.register_craft({
    type = "shaped",
    output = "envelopes:envelope_blank 1",
    recipe = {
        {"", "", ""},
        {"default:paper", "default:paper", "default:paper"},
        {"default:paper", "default:paper", "default:paper"}
    }
})
