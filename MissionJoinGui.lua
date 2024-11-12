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
