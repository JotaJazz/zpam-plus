import unittest

import test_server


class ParseTest(unittest.TestCase):
    def test_cvar_value(self):
        self.assertEqual(test_server.cvar_value('"sv_fps" is: "40^7" default: "20^7"\n'), "40")
        self.assertEqual(test_server.cvar_value('"pam_mode" is: "comp_mr12^7" default: "comp^7"'), "comp_mr12")
        self.assertEqual(test_server.cvar_value('"g_password" is: "^7" default: "^7"'), "")
        self.assertIsNone(test_server.cvar_value("Unknown command"))
        self.assertIsNone(test_server.cvar_value(None))

    def test_scan(self):
        log = "\n".join([
            "InitGame",
            "------------ zPAM Errors -----------",
            "******* script runtime error *******",
            "assert fail: timing selfTest: wait 1 lasted 500 ms",
            "ERROR: UDP_OpenSocket: bind: Address already in use",
            "a normal line",
        ])
        self.assertEqual([w for w, _ in test_server.scan(log)],
                         ["zPAM installation error", "script runtime error", "failed self-test", "port in use"])
        self.assertEqual(test_server.scan("InitGame\nHitch warning: 2596 msec frame time"), [])

    def test_build_line(self):
        self.assertEqual(test_server.build_line("CoD2 MP 1.3 build linux-x64 Nov  7 2026"), "1.3")
        self.assertEqual(test_server.build_line("CoD2 MP 1.0 build linux-x64"), "1.0")
        self.assertIsNone(test_server.build_line("nothing"))


if __name__ == "__main__":
    unittest.main()
