Hooks:PostHook(MissionJoinGui, "_layout_filters",
    "BetterServerBrowser_MissionJoinGui__layout_filters",
    function(self)
        -- hide friends-only-filter
        self._friends_only_button:hide()

        -- shift other filter positions up accordingly
        self._in_camp_servers_only:set_y(self._friends_only_button:y())
        self._distance_filter_stepper:set_y(self._in_camp_servers_only:y() + 50)
        self._difficulty_filter_stepper:set_y(self._distance_filter_stepper:y() + 50)
        self._mission_filter_stepper:set_y(self._difficulty_filter_stepper:y() + 50)

        -- fix move pointers
        self._in_camp_servers_only._on_menu_move.up = "mission_filter_stepper"
        self._mission_filter_stepper._on_menu_move.up = "in_camp_servers_only"
    end
)

Hooks:PostHook(MissionJoinGui, "_layout_footer_buttons",
    "BetterServerBrowser_MissionJoinGui__layout_footer_buttons",
    function(self)
        -- fix move pointer
        self._join_button._on_menu_move.left = "in_camp_servers_only"
    end
)

Hooks:PostHook(MissionJoinGui, "_render_filters",
    "BetterServerBrowser_MissionJoinGui__render_filters",
    function(self)
        -- force disable previously hidden friends-only-filter
        self._friends_only_button:set_value_and_render(false)
    end
)

Hooks:PostHook(MissionJoinGui, "_filters_set_selected_filters",
    "BetterServerBrowser_MissionJoinGui__filters_set_selected_filters",
    function(self)
        -- fix selection (vanilla selects friends-only here, so we select the next one: in_camp_servers)
        self._in_camp_servers_only:set_selected(true)
    end
)

function MissionJoinGui:_find_online_games_win32(friends_only)
    local function f(info)
        managers.network.matchmake:search_lobby_done()

        local room_list = info.room_list
        local attribute_list = info.attribute_list
        local dead_list = {}

        for id, _ in pairs(self._active_server_jobs) do
            dead_list[id] = true
        end

        for i, room in ipairs(room_list) do
            local host_name = tostring(room.owner_name)
            local attributes_numbers = attribute_list[i].numbers

            if managers.network.matchmake:is_server_ok(friends_only, room.owner_id, attributes_numbers) then
                dead_list[room.room_id] = nil

                local level_id = attributes_numbers[1]
                local difficulty_id = attributes_numbers[2]
                local permission_id = attributes_numbers[3]
                local state = attributes_numbers[4]
                local num_plrs = attributes_numbers[5]
                -- local drop_in = attributes_numbers[6]
                -- local min_level = attributes_numbers[7]
                local kick_option = attributes_numbers[8]
                -- local job_class = attributes_numbers[9]
                local job_plan = attributes_numbers[10]
                -- local region = attributes_numbers[11]
                local challenge_card = attributes_numbers[12]
                local players_info = attributes_numbers[13]
                local job_id = attributes_numbers[14]
                local progress = attributes_numbers[15]
                local mission_type = attributes_numbers[16]
                local players_info_1 = attributes_numbers[17]
                local players_info_2 = attributes_numbers[18]
                local players_info_3 = attributes_numbers[19]
                local players_info_4 = attributes_numbers[20]

                local job_name = ""
                local level_name = ""
                local difficulty = self:translate(tweak_data:get_difficulty_string_name_from_index(difficulty_id), true)
                local state_string_id = tweak_data:index_to_server_state(state)
                local state_name = state_string_id and
                    managers.localization:text("menu_lobby_server_state_" .. state_string_id) or "UNKNOWN"

                if challenge_card == "nocards" or challenge_card == "" or challenge_card == "value_pending" then
                    challenge_card = ""
                end

                if players_info == "value_pending" then
                    players_info = ""
                end

                if progress == "value_pending" then
                    progress = ""
                end

                if mission_type == "value_pending" then
                    mission_type = ""
                end

                if level_id == OperationsTweakData.IN_LOBBY then
                    level_name = self:translate("menu_mission_select_in_lobby")
                    job_name = self:translate("menu_mission_select_in_lobby")
                elseif tonumber(mission_type) == OperationsTweakData.JOB_TYPE_OPERATION then
                    level_name = ""
                    job_name = ""

                    local operation_data = tweak_data.operations.missions[job_id]

                    if operation_data and operation_data.events and operation_data.events[level_id] then
                        level_name = self:translate(operation_data.events[level_id].name_id)
                        job_name = self:translate(operation_data.name_id)
                    end
                elseif tonumber(mission_type) == OperationsTweakData.JOB_TYPE_RAID then
                    local mission_data = tweak_data.operations.missions[job_id]

                    level_name = ""

                    if mission_data and mission_data.name_id then
                        level_name = self:translate(mission_data.name_id)
                    end

                    job_name = self:translate("menu_mission_selected_mission_type_raid")
                end

                local relation = Steam:friend_relationship(room.owner_id)
                local is_friend = relation == "friend"
                local permission = self:translate("menu_permission_" ..
                    tweak_data:index_to_permission(permission_id):gsub("_only", ""))

                if level_name == "" or job_name == "" then
                    dead_list[room.room_id] = true
                else
                    local job_data = {
                        challenge_card = challenge_card,
                        custom_text = room.custom_text,
                        difficulty = difficulty,
                        difficulty_id = difficulty_id,
                        host_name = host_name,
                        id = room.room_id,
                        is_friend = is_friend,
                        job_id = job_id,
                        job_name = job_name,
                        job_plan = job_plan,
                        kick_option = kick_option,
                        level_id = level_id,
                        level_name = level_name,
                        mission_type = mission_type,
                        num_plrs = num_plrs,
                        players_info = players_info,
                        players_info_1 = players_info_1,
                        players_info_2 = players_info_2,
                        players_info_3 = players_info_3,
                        players_info_4 = players_info_4,
                        progress = progress,
                        room_id = room.room_id,
                        state = state,
                        state_name = state_name,
                        xuid = room.xuid,
                        permission = permission,
                    }

                    if not self._active_server_jobs[room.room_id] then
                        if table.size(self._active_jobs) + table.size(self._active_server_jobs) < self._tweak_data.total_active_jobs and table.size(self._active_server_jobs) < self._max_active_server_jobs then
                            self._active_server_jobs[room.room_id] = {
                                added = false,
                                alive_time = 0,
                            }

                            self:add_gui_job(job_data)
                        end
                    else
                        self:update_gui_job(job_data)
                    end
                end
            end
        end

        for id, _ in pairs(dead_list) do
            self._active_server_jobs[id] = nil

            self:remove_gui_job(id)
        end

        if self._table_servers and self._table_servers:is_alive() then
            self._table_servers:refresh_data()
            self._server_list_scrollable_area:setup_scroll_area()
            self._table_servers:select_table_row_by_row_idx(1)
            self:_select_game_from_list()

            if self._selected_row_data then
                self:_set_game_description_data(self._selected_row_data[6].value)
                self._game_description_panel:show()
                self._filters_panel:hide()
                self:_filters_set_selected_server_table()
            else
                self._game_description_panel:hide()
                self._filters_panel:show()
                self:_filters_set_selected_filters()
            end
        end

        self._apply_filters_button:show()
    end

    managers.network.matchmake:register_callback("search_lobby", f)
    managers.network.matchmake:search_lobby(friends_only)

    local function usrs_f(success, amount)
        print("usrs_f", success, amount)

        if success then
            self:set_players_online(amount)
        end
    end

    Steam:sa_handler():concurrent_users_callback(usrs_f)
    Steam:sa_handler():get_concurrent_users()
end

function MissionJoinGui:_layout_server_list_table()
    self._servers_title_label = self._list_panel:label({
        color = tweak_data.gui.colors.raid_red,
        font = tweak_data.gui.fonts.din_compressed,
        font_size = tweak_data.gui.font_sizes.title,
        h = 69,
        name = "servers_title_label",
        text = utf8.to_upper(managers.localization:text("menu_mission_join_server_list_title")),
        vertical = "top",
        w = 320,
    })
    self._server_list_scrollable_area = self._list_panel:scrollable_area({
        h = 720,
        name = "servers_table_scrollable_area",
        scroll_step = 35,
        w = 1216,
        y = 96,
    })
    self._params_servers_table = {
        loop_items = true,
        name = "servers_table",
        on_selected_callback = callback(self, self, "bind_controller_inputs"),
        scrollable_area_ref = self._server_list_scrollable_area,
        table_params = {
            columns = {
                {
                    align = "left",
                    cell_class = RaidGUIControlTableCell,
                    color = tweak_data.gui.colors.raid_grey,
                    header_padding = 32,
                    header_text = self:translate("menu_mission_join_server_list_columns_mission_type", true),
                    highlight_color = tweak_data.gui.colors.raid_white,
                    on_cell_click_callback = callback(self, self, "on_cell_click_servers_table"),
                    padding = 32,
                    selected_color = tweak_data.gui.colors.raid_red,
                    vertical = "center",
                    w = 450,
                },
                {
                    align = "left",
                    cell_class = RaidGUIControlTableCell,
                    color = tweak_data.gui.colors.raid_grey,
                    header_padding = 0,
                    header_text = self:translate("menu_mission_join_server_list_columns_difficulty", true),
                    highlight_color = tweak_data.gui.colors.raid_white,
                    on_cell_click_callback = callback(self, self, "on_cell_click_servers_table"),
                    padding = 0,
                    selected_color = tweak_data.gui.colors.raid_red,
                    vertical = "center",
                    w = 130,
                },
                {
                    align = "left",
                    cell_class = RaidGUIControlTableCell,
                    color = tweak_data.gui.colors.raid_grey,
                    header_padding = 0,
                    header_text = self:translate("menu_mission_join_server_list_columns_host_name", true),
                    highlight_color = tweak_data.gui.colors.raid_white,
                    on_cell_click_callback = callback(self, self, "on_cell_click_servers_table"),
                    padding = 0,
                    selected_color = tweak_data.gui.colors.raid_red,
                    vertical = "center",
                    w = 370,
                },
                {
                    align = "left",
                    cell_class = RaidGUIControlTableCell,
                    color = tweak_data.gui.colors.raid_grey,
                    header_padding = 0,
                    header_text = self:translate("menu_mission_join_server_list_columns_players", true),
                    highlight_color = tweak_data.gui.colors.raid_white,
                    on_cell_click_callback = callback(self, self, "on_cell_click_servers_table"),
                    padding = 0,
                    selected_color = tweak_data.gui.colors.raid_red,
                    vertical = "center",
                    w = 120,
                },
                {
                    align = "left",
                    cell_class = RaidGUIControlTableCell,
                    color = tweak_data.gui.colors.raid_grey,
                    header_padding = 0,
                    header_text = self:translate("menu_mission_join_server_list_columns_permission", true),
                    highlight_color = tweak_data.gui.colors.raid_white,
                    on_cell_click_callback = callback(self, self, "on_cell_click_servers_table"),
                    padding = 0,
                    selected_color = tweak_data.gui.colors.raid_red,
                    vertical = "center",
                    w = 170,
                },
            },
            data_source_callback = callback(self, self, "data_source_servers_table"),
            header_params = {
                font = tweak_data.gui.fonts.din_compressed,
                font_size = tweak_data.gui.font_sizes.small,
                header_height = 32,
                text_color = tweak_data.gui.colors.raid_white,
            },
            row_params = {
                color = tweak_data.gui.colors.raid_grey,
                font = tweak_data.gui.fonts.din_compressed,
                font_size = tweak_data.gui.font_sizes.extra_small,
                height = MissionJoinGui.SERVER_TABLE_ROW_HEIGHT,
                highlight_color = tweak_data.gui.colors.raid_white,
                on_row_click_callback = callback(self, self, "on_row_clicked_servers_table"),
                on_row_double_clicked_callback = callback(self, self, "on_row_double_clicked_servers_table"),
                on_row_select_callback = callback(self, self, "on_row_selected_servers_table"),
                row_background_color = tweak_data.gui.colors.raid_white:with_alpha(0),
                row_highlight_background_color = tweak_data.gui.colors.raid_white:with_alpha(0.1),
                row_selected_background_color = tweak_data.gui.colors.raid_white:with_alpha(0.1),
                selected_color = tweak_data.gui.colors.raid_red,
                spacing = 0,
            },
        },
        use_row_dividers = true,
        use_selector_mark = true,
        w = self._server_list_scrollable_area:w(),
    }

    self._table_servers = self._server_list_scrollable_area:get_panel():table(self._params_servers_table)

    self._server_list_scrollable_area:setup_scroll_area()
end

function MissionJoinGui:data_source_servers_table()
    local missions = {}

    if not self._gui_jobs then
        self._gui_jobs = {}
    end

    local mission_data

    for _, value in pairs(self._gui_jobs) do
        if utf8.to_lower(value.level_id) == OperationsTweakData.IN_LOBBY or utf8.to_lower(value.level_id) == OperationsTweakData.ENTRY_POINT_LEVEL then
            mission_data = {
                info = value.level_name,
                text = self:translate(tweak_data.operations.missions.camp.name_id, true),
                value = value.room_id,
            }
        elseif utf8.to_upper(value.job_name) == RaidJobManager.SINGLE_MISSION_TYPE_NAME then
            mission_data = {
                info = value.level_name,
                text = utf8.to_upper(value.level_name),
                value = value.room_id,
            }
        elseif value.progress ~= nil then
            mission_data = {
                info = value.level_name,
                text = utf8.to_upper(value.job_name .. " " .. value.progress .. ": " .. value.level_name),
                value = value.room_id,
            }
        else
            mission_data = {
                info = value.level_name,
                text = utf8.to_upper(value.job_name .. " " .. "WRONG PROGRESS" .. ": " .. value.level_name),
                value = value.room_id,
            }
        end

        local host_name = value.host_name

        if managers.user:get_setting("capitalize_names") then
            host_name = utf8.to_upper(host_name)
        end

        table.insert(missions, {
            mission_data,
            {
                info = value.difficulty,
                text = utf8.to_upper(value.difficulty),
                value = value.room_id,
            },
            {
                info = value.host_name,
                text = host_name,
                value = value.room_id,
            },
            {
                info = value.num_plrs .. "",
                text = value.num_plrs .. "",
                value = value.room_id,
            },
            {
                info = value.permission .. "",
                text = utf8.to_upper(value.permission) .. "",
                value = value.room_id,
            },
            {
                value = value,
            },
        })
    end

    return missions
end

function MissionJoinGui:on_row_clicked_servers_table(row_data, row_index)
    self:_select_server_list_item(row_data[6].value)
end

function MissionJoinGui:on_row_double_clicked_servers_table(row_data, row_index)
    self:_select_server_list_item(row_data[6].value)
    self:_join_game()
end

function MissionJoinGui:on_row_selected_servers_table(row_data, row_index)
    self:_select_server_list_item(row_data[6].value)
end

function MissionJoinGui:on_cell_click_servers_table(data)
    self:_select_server_list_item(self._selected_row_data[6].value)
end
