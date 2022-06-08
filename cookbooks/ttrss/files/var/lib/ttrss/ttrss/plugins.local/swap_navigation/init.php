<?php
class Swap_Navigation extends Plugin {

        function about() {
                return array(1.0, "Swap feed / article navigation keys", "fornellas");
        }

        function init($host) {
                $host->add_hook($host::HOOK_HOTKEY_MAP, $this);
        }

        function hook_hotkey_map($hotkeys) {
                $hotkeys["n"] = "next_feed";
                $hotkeys["N"] = "next_unread_feed";
                $hotkeys["p"] = "prev_feed";
                $hotkeys["P"] = "prev_unread_feed";
                $hotkeys["j"] = "next_article_noscroll";
                $hotkeys["k"] = "prev_article_noscroll";
                $hotkeys["J"] = "article_page_down";
                $hotkeys["K"] = "article_page_up";
                return $hotkeys;
        }

        function api_version() {
                return 2;
        }
}