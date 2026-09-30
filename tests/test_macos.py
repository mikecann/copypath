"""Run the real macOS launcher with an isolated clipboard command and install dir."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class MacLauncherTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="copypath-tests-")
        self.addCleanup(self.temp.cleanup)
        # macOS /var is a symlink; subprocess cwd reports its physical path.
        self.root = Path(self.temp.name).resolve()
        self.repo = self.root / "clone with spaces"
        self.repo.mkdir()
        source = Path(__file__).resolve().parents[1]
        for name in ("copypath", "install.sh"):
            shutil.copy2(source / name, self.repo / name)
        self.bin = self.root / "bin with spaces"
        self.bin.mkdir()
        self.clipboard = self.root / "clipboard"
        pbcopy = self.bin / "pbcopy"
        pbcopy.write_text('#!/bin/sh\ncat > "$TEST_CLIPBOARD"\n')
        pbcopy.chmod(0o755)
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}",
                        TEST_CLIPBOARD=str(self.clipboard))

    def run_command(self, *args):
        return subprocess.run(args, cwd=self.root, env=self.env, check=True,
                              text=True, capture_output=True)

    def install(self):
        self.run_command("bash", str(self.repo / "install.sh"), str(self.bin))

    def test_install_is_idempotent_and_preserves_other_tools(self):
        other = self.bin / "other-tool"
        other.write_text("keep this")
        self.install()
        self.install()
        self.assertEqual((self.bin / "copypath").resolve(), self.repo / "copypath")
        self.assertEqual(other.read_text(), "keep this")

    def test_installed_launcher_copies_current_directory(self):
        self.install()
        result = self.run_command(str(self.bin / "copypath"))
        self.assertEqual(self.clipboard.read_text(), str(self.root))
        self.assertEqual(result.stdout, f"Copied: {self.root}\n")

    def test_relative_absolute_and_missing_paths(self):
        self.install()
        file = self.root / "file with spaces.txt"
        file.touch()
        for argument in (file.name, str(file), "missing folder/../missing file.txt"):
            with self.subTest(argument=argument):
                self.run_command(str(self.bin / "copypath"), argument)
                self.assertEqual(self.clipboard.read_text(), os.path.abspath(argument)
                                 if os.path.isabs(argument) else
                                 os.path.normpath(str(self.root / argument)))


if __name__ == "__main__":
    unittest.main()
