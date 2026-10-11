import contextlib
import io
import os
import subprocess
import tempfile
import tomllib
import unittest
from copy import deepcopy
from pathlib import Path
from unittest.mock import patch

import tomli_w

import export


class CleanSettingsTests(unittest.TestCase):
    def test_preserves_reusable_preferences_and_named_bar_order(self):
        data = {
            "bar": {
                "sidebar": {
                    "position": "left", "start": ["cpu", "ram"], "center": [],
                    "end": ["clock"], "background_opacity": 0.7,
                    "monitor": {"laptop": {"match": "eDP-1", "enabled": True}},
                    "monitors": ["eDP-1"],
                },
                "default": {
                    "position": "top", "start": ["launcher", "workspaces"],
                    "center": ["clock"], "end": ["volume", "control-center"],
                    "capsule_group": [{"id": "sysmon", "members": ["cpu", "ram"]}],
                    "monitors": ["DP-1"],
                },
            },
            "theme": {"mode": "dark", "source": "custom", "custom_palette": "stylix"},
            "shell": {"launcher": {"providers": {"session": {"global": True}}}},
            "widget": {"clock": {"format": "%H:%M"}},
            "control_center": {"calendar": {"show_events_card": True}},
            "audio": {"enable_sounds": False},
            "brightness": {"enable_ddcutil": True},
            "location": {"address": "Erechim"},
            "system": {"monitor": {"gpu_poll_seconds": 0}},
            "weather": {"effects": True},
            "keybinds": {"cancel": ["escape"]},
            "accessibility": {"ui_scale": 1.1},
        }
        expected = deepcopy(data)
        del expected["bar"]["sidebar"]["monitor"]
        del expected["bar"]["sidebar"]["monitors"]
        del expected["bar"]["default"]["monitors"]
        original = deepcopy(data)
        cleaned = export.clean_settings(data)
        self.assertEqual(cleaned, expected)
        self.assertEqual(list(cleaned["bar"]), ["sidebar", "default"])
        self.assertEqual(data, original)

    def test_strips_nix_managed_fields_only(self):
        data = {
            "shell": {"font_family": "Sans", "avatar_path": "/home/user/.face",
                      "telemetry_enabled": False},
            "bar": {"default": {"background_opacity": 0.9, "capsule_opacity": 0.9,
                                "capsule": True}},
            "dock": {"background_opacity": 0.9, "enabled": True},
            "notification": {"background_opacity": 0.9, "position": "top_right"},
            "osd": {"background_opacity": 0.9, "hide_delay_ms": 2000},
            "widget": {
                "cpu": {"font_family": "Mono", "stat": "cpu_usage"},
                "cpu_temp": {"font_family": "Mono", "stat": "cpu_temp"},
                "ram": {"font_family": "Mono", "stat": "ram_used"},
                "temp": {"font_family": "Mono", "show_value": False},
                "clock": {"font_family": "Custom"},
            },
        }
        self.assertEqual(export.clean_settings(data), {
            "shell": {"telemetry_enabled": False},
            "bar": {"default": {"capsule": True}},
            "dock": {"enabled": True},
            "notification": {"position": "top_right"},
            "osd": {"hide_delay_ms": 2000},
            "widget": {
                "cpu": {"stat": "cpu_usage"}, "cpu_temp": {"stat": "cpu_temp"},
                "ram": {"stat": "ram_used"}, "clock": {"font_family": "Custom"},
                "temp": {"show_value": False},
            },
        })

    def test_excludes_accounts_plugins_hardware_and_unsupported_roots(self):
        data = {
            "calendar": {"account": [{"username": "user", "password": "secret"}]},
            "battery": {"device": [{"name": "BAT0", "threshold": 10}]},
            "plugin_settings": {"author/plugin": {"token": "secret"}},
            "config_version": 5,
            "include": ["/home/user/custom.toml"],
            "includes": ["other.toml"],
            "idle": {"behavior": {"lock": {"enabled": True}}},
            "hooks": {"started": "custom-command"},
            "greeter": {"enabled": True},
            "files": {"custom": "/home/user/config"},
            "templates": {"custom": "local-template"},
            "unknown": {"credential": "secret"},
            "plugins": {
                "enabled": ["author/installed"], "auto_update": "none",
                "sources": ["https://user:secret@example.invalid/plugins"],
                "metadata": {"token": "secret"}, "settings": {"key": "secret"},
            },
            "theme": {
                "mode": "light", "source": "builtin", "builtin": "Noctalia",
                "templates": {"user": {"custom": {"output_path": "/home/user/theme"}}},
            },
            "widget": {"battery": {"display_mode": "graphic"}},
        }
        self.assertEqual(export.clean_settings(data), {
            "plugins": {"enabled": ["author/installed"], "auto_update": "none"},
            "theme": {"mode": "light", "source": "builtin", "builtin": "Noctalia"},
            "widget": {"battery": {"display_mode": "graphic"}},
        })

    def test_excludes_widget_placements_but_keeps_global_preferences(self):
        layout = {
            "enabled": True, "grid": {"visible": False, "cell_size": 16},
            "widget": {"clock": {"output": "DP-1", "cx": 960, "cy": 540}},
            "widget_order": ["clock"], "schema_version": 2,
        }
        self.assertEqual(export.clean_settings({
            "desktop_widgets": deepcopy(layout), "lockscreen_widgets": deepcopy(layout),
        }), {
            "desktop_widgets": {"enabled": True, "grid": {"visible": False, "cell_size": 16}},
            "lockscreen_widgets": {"enabled": True, "grid": {"visible": False, "cell_size": 16}},
        })

    def test_excludes_monitor_and_sensor_identifiers(self):
        data = {
            "dock": {"enabled": True, "monitor": {"laptop": {"match": "eDP-1"}}},
            "brightness": {"enable_ddcutil": True, "monitor": {"external": {"ddc_bus": 3}},
                           "ignore_mmids": ["display-id"]},
            "notification": {"monitors": ["DP-1"], "position": "top_right"},
            "osd": {"monitors": ["DP-1"], "hide_delay_ms": 2000},
            "lockscreen": {"monitors": ["DP-1"], "wallpaper": "/home/user/lock.png",
                           "enabled": True},
            "system": {"monitor": {"cpu_temp_sensor_path": "/sys/hardware/temp1_input",
                                   "gpu_poll_seconds": 0}},
        }
        self.assertEqual(export.clean_settings(data), {
            "dock": {"enabled": True},
            "brightness": {"enable_ddcutil": True},
            "notification": {"position": "top_right"},
            "osd": {"hide_delay_ms": 2000},
            "lockscreen": {"enabled": True},
            "system": {"monitor": {"gpu_poll_seconds": 0}},
        })

    def test_excludes_wallpaper_paths_but_keeps_effects(self):
        data = {"wallpaper": {
            "enabled": True, "transition": ["fade", "disc"], "edge_smoothness": 0.05,
            "automation": {"enabled": False, "order": "random"},
            "default": {"path": "/nix/store/image.png"},
            "last": {"path": "/home/user/last.png"},
            "monitors": {"DP-1": {"path": "/home/user/monitor.png"}},
            "monitor": {"DP-1": {"directory": "/home/user/wallpapers"}},
            "favorites": ["/home/user/favorite.png"],
            "favorite": [{"path": "/nix/store/favorite.png"}],
            "directory": "/home/user/Pictures", "directory_light": "relative/light",
            "directory_dark": "$XDG_PICTURES_DIR/dark",
        }}
        cleaned = export.clean_settings(data)
        self.assertEqual(cleaned, {"wallpaper": {
            "enabled": True, "transition": ["fade", "disc"], "edge_smoothness": 0.05,
            "automation": {"enabled": False, "order": "random"},
        }})
        self.assertNotIn("/nix/store", tomli_w.dumps(cleaned))

    def test_migrates_centered_session_and_removes_obsolete_search(self):
        self.assertEqual(export.clean_settings({"shell": {"panel": {
            "session_placement": "centered", "session_position": "top_left",
            "launcher_session_search": True, "borders": False,
        }}}), {"shell": {"panel": {
            "session_placement": "floating", "session_position": "center", "borders": False,
        }}})
        attached = {"shell": {"panel": {
            "session_placement": "attached", "session_position": "top_right",
        }}}
        self.assertEqual(export.clean_settings(attached), attached)

    def test_rejects_main_default_collision_and_preserves_main_alone(self):
        with self.assertRaisesRegex(ValueError, r"bar\.main and bar\.default.*migration"):
            export.clean_settings({"bar": {"main": {}, "default": {}}})
        data = {"bar": {"main": {"start": ["clock"], "background_opacity": 0.8}}}
        self.assertEqual(export.clean_settings(data), data)

    def test_prunes_empty_dictionaries_not_explicit_empty_lists(self):
        self.assertEqual(export.clean_settings({
            "shell": {"font_family": "Sans", "panel": {}, "mpris": {"blacklist": []},
                      "session": {"actions": [{"action": "lock", "empty": {}}, {}]}},
            "widget": {"cpu": {"font_family": "Mono"}},
            "plugins": {"enabled": []},
            "bar": {"default": {"start": [], "center": [], "end": []}},
            "lockscreen": {"transition": []},
            "desktop_widgets": {"widget": {}, "widget_order": []},
        }), {
            "shell": {"mpris": {"blacklist": []}, "session": {"actions": [{"action": "lock"}, {}]}},
            "plugins": {"enabled": []},
            "bar": {"default": {"start": [], "center": [], "end": []}},
            "lockscreen": {"transition": []},
        })

    def test_cleaning_is_idempotent_and_toml_round_trips(self):
        data = {
            "shell": {"avatar_path": "/home/user/.face", "panel": {"session_placement": "centered"}},
            "bar": {"default": {"start": ["launcher"], "center": [], "end": ["clock"]}},
            "theme": {"mode": "dark", "source": "custom", "custom_palette": "stylix"},
            "plugins": {"enabled": ["author/plugin"], "auto_update": "none"},
            "widget": {"clock": {"format": "%H:%M", "scale": 1.25}},
            "wallpaper": {"directory": "/home/user/Pictures", "enabled": True},
        }
        cleaned = export.clean_settings(data)
        self.assertEqual(export.clean_settings(cleaned), cleaned)
        self.assertEqual(tomllib.loads(tomli_w.dumps(cleaned)), cleaned)


class ExportTests(unittest.TestCase):
    def test_native_export_is_validated_in_empty_isolated_xdg_before_replace(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output = root / "settings.toml"
            output.write_text("previous baseline\n")
            isolated_paths = []
            candidate_paths = []
            stdout = io.StringIO()
            environment = {
                name: str(root / f"real-{name}")
                for name in (
                    "HOME", "XDG_CONFIG_HOME", "XDG_STATE_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME",
                    "NOCTALIA_CONFIG_HOME", "NOCTALIA_STATE_HOME", "NOCTALIA_DATA_HOME",
                )
            }
            for path in environment.values():
                Path(path).mkdir()
                (Path(path) / "sentinel").write_text("untouched")

            def run(command, **kwargs):
                if command == ["noctalia", "config", "export", "merged"]:
                    self.assertTrue(kwargs["check"])
                    self.assertNotIn("env", kwargs)
                    return subprocess.CompletedProcess(
                        command, 0,
                        '[shell]\nfont_family = "Sans"\n[theme]\nmode = "dark"\n', "",
                    )
                self.assertEqual(command[:3], ["noctalia", "config", "validate"])
                candidate = Path(command[3])
                candidate_paths.append(candidate)
                self.assertEqual(candidate.parent, output.parent)
                self.assertNotEqual(candidate, output)
                self.assertEqual(
                    tomllib.loads(candidate.read_text()), {"theme": {"mode": "dark"}}
                )
                self.assertEqual(output.read_text(), "previous baseline\n")
                env = kwargs["env"]
                self.assertEqual(env["PATH"], os.environ["PATH"])
                for name, real_path in environment.items():
                    isolated = Path(env[name])
                    isolated_paths.append(isolated)
                    self.assertNotEqual(str(isolated), real_path)
                    self.assertTrue(isolated.is_dir())
                    self.assertEqual(list(isolated.iterdir()), [])
                self.assertEqual(len({path.parent for path in isolated_paths}), 1)
                self.assertTrue(kwargs["capture_output"])
                self.assertTrue(kwargs["text"])
                return subprocess.CompletedProcess(command, 0, "OK\n", "")

            with (
                patch.dict(os.environ, environment),
                patch.object(export.subprocess, "run", side_effect=run) as native,
                patch.object(export.os, "replace", wraps=os.replace) as replace,
                contextlib.redirect_stdout(stdout),
            ):
                self.assertEqual(export.main([str(output)]), 0)
            self.assertEqual(native.call_count, 2)
            replace.assert_called_once_with(candidate_paths[0], output)
            self.assertEqual(tomllib.loads(output.read_text()), {"theme": {"mode": "dark"}})
            self.assertTrue(
                all(not path.exists() for path in candidate_paths + isolated_paths)
            )
            for path in environment.values():
                self.assertEqual(list(Path(path).iterdir()), [Path(path) / "sentinel"])
                self.assertEqual((Path(path) / "sentinel").read_text(), "untouched")
            self.assertIn(str(output), stdout.getvalue())
            self.assertIn("stripped", stdout.getvalue())
            self.assertIn("review the diff", stdout.getvalue())

    def test_input_file_skips_native_export_and_only_runs_validation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "raw.toml"
            source.write_text(
                '[theme]\nmode = "light"\n[wallpaper]\ndirectory = "/local"\n'
            )
            output = root / "settings.toml"
            with (
                patch.object(
                    export.subprocess, "run",
                    return_value=subprocess.CompletedProcess([], 0, "OK", ""),
                ) as native,
                contextlib.redirect_stdout(io.StringIO()),
            ):
                self.assertEqual(export.main([str(output), "--input", str(source)]), 0)
            self.assertEqual(native.call_count, 1)
            self.assertEqual(
                native.call_args.args[0][:3], ["noctalia", "config", "validate"]
            )
            self.assertEqual(tomllib.loads(output.read_text()), {"theme": {"mode": "light"}})
            self.assertEqual(set(root.iterdir()), {source, output})

    def test_invalid_or_warning_validation_preserves_existing_output(self):
        results = [(1, "ERROR theme.mode: invalid\n"), (0, "WARN theme.unknown: unknown\n")]
        for returncode, diagnostic in results:
            with (
                self.subTest(returncode=returncode),
                tempfile.TemporaryDirectory() as directory,
            ):
                root = Path(directory)
                source = root / "raw.toml"
                source.write_text('[theme]\nmode = "dark"\n')
                output = root / "settings.toml"
                output.write_bytes(b"previous baseline\n")
                candidates = []
                isolated_paths = []
                stderr = io.StringIO()

                def run(command, **kwargs):
                    candidates.append(Path(command[3]))
                    isolated_paths.extend(
                        Path(kwargs["env"][name])
                        for name in ("XDG_CONFIG_HOME", "XDG_STATE_HOME", "XDG_CACHE_HOME")
                    )
                    self.assertTrue(candidates[0].is_file())
                    return subprocess.CompletedProcess(command, returncode, diagnostic, "")

                with (
                    patch.object(export.subprocess, "run", side_effect=run),
                    patch.object(export.os, "replace") as replace,
                    contextlib.redirect_stderr(stderr),
                ):
                    self.assertEqual(export.main([str(output), "--input", str(source)]), 1)
                replace.assert_not_called()
                self.assertEqual(output.read_bytes(), b"previous baseline\n")
                self.assertTrue(
                    all(not path.exists() for path in candidates + isolated_paths)
                )
                self.assertEqual(set(root.iterdir()), {source, output})
                self.assertIn(diagnostic.strip(), stderr.getvalue())

    def test_validation_subprocess_error_cleans_temporary_file(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "raw.toml"
            source.write_text('[theme]\nmode = "dark"\n')
            output = root / "settings.toml"
            output.write_text("previous baseline\n")
            with (
                patch.object(
                    export.subprocess, "run", side_effect=OSError("validator unavailable")
                ),
                contextlib.redirect_stderr(io.StringIO()),
            ):
                self.assertEqual(export.main([str(output), "--input", str(source)]), 1)
            self.assertEqual(output.read_text(), "previous baseline\n")
            self.assertEqual(set(root.iterdir()), {source, output})

    def test_refuses_existing_and_dangling_symlink_outputs(self):
        for dangling in (False, True):
            with (
                self.subTest(dangling=dangling),
                tempfile.TemporaryDirectory() as directory,
            ):
                root = Path(directory)
                destination = root / "destination.toml"
                if not dangling:
                    destination.write_text("previous baseline\n")
                output = root / "settings.toml"
                output.symlink_to(destination)
                with (
                    patch.object(export.subprocess, "run") as native,
                    contextlib.redirect_stderr(io.StringIO()) as stderr,
                ):
                    self.assertEqual(export.main([str(output)]), 1)
                native.assert_not_called()
                self.assertTrue(output.is_symlink())
                self.assertIn("refusing symlink", stderr.getvalue())
                if not dangling:
                    self.assertEqual(destination.read_text(), "previous baseline\n")

    def test_refuses_output_changed_to_symlink_during_validation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "raw.toml"
            source.write_text('[theme]\nmode = "dark"\n')
            destination = root / "destination.toml"
            destination.write_text("untouched\n")
            output = root / "settings.toml"

            def run(command, **kwargs):
                output.symlink_to(destination)
                return subprocess.CompletedProcess(command, 0, "OK", "")

            with (
                patch.object(export.subprocess, "run", side_effect=run),
                patch.object(export.os, "replace") as replace,
                contextlib.redirect_stderr(io.StringIO()),
            ):
                self.assertEqual(export.main([str(output), "--input", str(source)]), 1)
            replace.assert_not_called()
            self.assertTrue(output.is_symlink())
            self.assertEqual(destination.read_text(), "untouched\n")
            self.assertEqual(set(root.iterdir()), {source, destination, output})

    def test_refuses_symlinked_output_parent(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            state = root / "live-state"
            state.mkdir()
            output = state / "settings.toml"
            output.write_text("untouched\n")
            linked = root / "linked-state"
            linked.symlink_to(state, target_is_directory=True)
            with (
                patch.object(export.subprocess, "run") as native,
                contextlib.redirect_stderr(io.StringIO()) as stderr,
            ):
                self.assertEqual(export.main([str(linked / "settings.toml")]), 1)
            native.assert_not_called()
            self.assertIn("refusing symlink", stderr.getvalue())
            self.assertEqual(output.read_text(), "untouched\n")
            self.assertEqual(set(state.iterdir()), {output})

    def test_missing_parent_is_not_created(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "missing" / "settings.toml"
            with (
                patch.object(export.subprocess, "run") as native,
                contextlib.redirect_stderr(io.StringIO()) as stderr,
            ):
                self.assertEqual(export.main([str(output)]), 1)
            native.assert_not_called()
            self.assertFalse(output.parent.exists())
            self.assertIn("parent must exist", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
