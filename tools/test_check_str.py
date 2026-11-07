import unittest

import check_str

GOOD = 'VERSION "1"\nREFERENCE A_B\nLANG_ENGLISH "Ready"\nLANG_SPANISH "Listo"\n\nENDMARKER\n'.encode("cp1252")


class CheckStrTest(unittest.TestCase):
    def test_good(self):
        self.assertEqual(check_str.check("x.str", GOOD), [])
        self.assertEqual(check_str.check("x.str", 'REFERENCE B\nLANG_ENGLISH "Grabación"\nENDMARKER\n'.encode("cp1252")), [])

    def errors(self, text, encoding="cp1252"):
        return " ".join(check_str.check("x.str", text.encode(encoding)))

    def test_bad(self):
        self.assertIn("LANG_ENGLISH", self.errors('REFERENCE A\nLANG_SPANISH "Listo"\nLANG_ENGLISH "Ready"\nENDMARKER\n'))
        self.assertIn("UTF-8", self.errors('REFERENCE A\nLANG_ENGLISH "Grabación"\nENDMARKER\n', "utf-8"))
        self.assertIn("ENDMARKER", self.errors('REFERENCE A\nLANG_ENGLISH "Ready"\n'))
        self.assertIn("duplicate", self.errors('REFERENCE A\nLANG_ENGLISH "a"\nREFERENCE A\nLANG_ENGLISH "b"\nENDMARKER\n'))
        self.assertIn("quoted", self.errors('REFERENCE A\nLANG_ENGLISH Ready\nENDMARKER\n'))
        self.assertIn("outside", self.errors('LANG_ENGLISH "a"\nENDMARKER\n'))
        self.assertIn("&&N", self.errors('REFERENCE A\nLANG_ENGLISH "a &&1 b &&1"\nENDMARKER\n'))
        self.assertIn("&&N", self.errors('REFERENCE A\nLANG_ENGLISH "a &&x"\nENDMARKER\n'))
        self.assertEqual(self.errors('REFERENCE A\nLANG_ENGLISH "&&1 and &&2"\nENDMARKER\n'), "")
        self.assertIn("4096", self.errors('REFERENCE A\nLANG_ENGLISH "' + "x" * 5000 + '"\nENDMARKER\n'))


if __name__ == "__main__":
    unittest.main()
