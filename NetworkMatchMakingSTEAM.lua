function NetworkMatchMakingSTEAM:search_lobby(friends_only)
    if not self:_has_callback("search_lobby") then
        return
    end

    self._search_friends_only = false
    local friend_lobbies = {}
    local num_updated_friends_lobbies = 0

    local function empty()
    end

    local info = {
        room_list = {},
        attribute_list = {}
    }
    local public_done = false
    local friends_wanted = true
    local friends_done = false

    local function refresh_public_lobbies()
        if not self.browser then
            return
        end

        local lobbies = self.browser:lobbies()

        if lobbies then
            for _, lobby in ipairs(lobbies) do
                if self._difficulty_filter == 0 or self._difficulty_filter == tonumber(lobby:key_value("difficulty")) then
                    table.insert(info.room_list, {
                        owner_id = lobby:key_value("owner_id"),
                        owner_name = lobby:key_value("owner_name"),
                        room_id = lobby:id(),
                        custom_text = lobby:key_value("custom_text")
                    })
                    table.insert(info.attribute_list, {
                        numbers = self:_lobby_to_numbers(lobby)
                    })
                end
            end
        end

        if not public_done then
            public_done = true
        end
        if not friends_wanted or friends_done then
            self:_call_callback("search_lobby", info)
        end
    end

    local function refresh_friends_lobby(lobby)
        lobby:setup_callback(empty)

        num_updated_friends_lobbies = num_updated_friends_lobbies + 1

        if num_updated_friends_lobbies >= #friend_lobbies then
            for _, friend_lobby in ipairs(friend_lobbies) do
                local ikey = friend_lobby:key_value(self._BUILD_SEARCH_INTEREST_KEY)
                if ikey ~= "value_missing" and ikey ~= "value_pending" then
                    table.insert(info.room_list, {
                        owner_id = friend_lobby:key_value("owner_id"),
                        owner_name = friend_lobby:key_value("owner_name"),
                        room_id = friend_lobby:id(),
                        custom_text = friend_lobby:key_value("custom_text")
                    })
                    table.insert(info.attribute_list, {
                        numbers = self:_lobby_to_numbers(friend_lobby)
                    })
                end
            end

            if not friends_done then
                friends_done = true
            end
            if public_done then
                self:_call_callback("search_lobby", info)
            end
        end
    end

    local user_id_to_filter_out = Steam:userid()

    if managers.criminals and managers.criminals:get_num_player_criminals() > 1 and managers.network and managers.network:session() and managers.network:session():all_peers() then
        user_id_to_filter_out = managers.network:session():all_peers()[1]:user_id()
    end

    -- FRIENDS ONLY LOBBIES

    if Steam:logged_on() and Steam:friends() then
        for _, friend in ipairs(Steam:friends()) do
            local friend_lobby = friend:lobby()

            if friend_lobby and user_id_to_filter_out ~= friend_lobby:key_value("owner_id") then
                local filtered = nil
                local filter_in_camp = tostring(self._lobby_filters.state.value)
                local filter_difficulty = tostring(self._difficulty_filter)
                local filter_job = tostring(self._lobby_filters.job_id.value)

                if filter_in_camp == "1" and filter_in_camp ~= friend_lobby:key_value("state") then
                    filtered = true
                elseif filter_difficulty ~= "0" and filter_difficulty ~= friend_lobby:key_value("difficulty") then
                    filtered = true
                elseif filter_job ~= "-1" and filter_job ~= friend_lobby:key_value("job_id") then
                    filtered = true
                end

                if not filtered then
                    table.insert(friend_lobbies, friend_lobby)
                end
            end
        end
    end

    if #friend_lobbies == 0 then
        friends_wanted = false
        friends_done = true
        if public_done then
            self:_call_callback("search_lobby", info)
        end
    else
        for _, lobby in ipairs(friend_lobbies) do
            lobby:setup_callback(refresh_friends_lobby)

            if lobby:key_value("state") == "value_pending" then
                lobby:request_data()
            else
                refresh_friends_lobby(lobby)
            end
        end
    end

    -- PUBLIC LOBBIES

    self.browser = LobbyBrowser(refresh_public_lobbies, empty)

    self.browser:set_interest_keys({
        "owner_id",
        "owner_name",
        "level",
        "difficulty",
        "permission",
        "state",
        "num_players",
        "drop_in",
        "min_level",
        "kick_option",
        "job_class_min",
        "job_class_max",
        self._BUILD_SEARCH_INTEREST_KEY
    })
    self.browser:set_distance_filter(self._distance_filter)
    self.browser:set_lobby_filter(self._BUILD_SEARCH_INTEREST_KEY, "true", "equal")
    self.browser:set_lobby_filter("owner_id", user_id_to_filter_out, "not_equal")
    for _, data in pairs(self._lobby_filters) do
        if data.value and data.value ~= -1 then
            self.browser:set_lobby_filter(data.key, data.value, data.comparision_type)
        end
    end
    self.browser:set_max_lobby_return_count(self._lobby_return_count)

    if Global.game_settings.playing_lan then
        self.browser:refresh_lan()
    else
        self.browser:refresh()
    end
end
