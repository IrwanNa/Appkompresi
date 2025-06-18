import unittest
from main import allowed_file, compress_deflate, decompress_deflate, compress_lzw, decompress_lzw

class TestBackendFunctions(unittest.TestCase):

    def test_allowed_file_valid_extensions(self):
        self.assertTrue(allowed_file("document.pdf"))
        self.assertTrue(allowed_file("slide.pptx"))
        self.assertTrue(allowed_file("notes.txt"))
        self.assertTrue(allowed_file("report.docx"))

    def test_allowed_file_invalid_extensions(self):
        self.assertFalse(allowed_file("image.jpg"))
        self.assertFalse(allowed_file("script.png"))
        self.assertFalse(allowed_file("style.json"))
        self.assertFalse(allowed_file(""))

    def test_deflate_compression_and_decompression(self):
        original_data = b"Ini adalah data untuk pengujian kompresi deflate."
        compressed = compress_deflate(original_data)
        decompressed = decompress_deflate(compressed)
        self.assertEqual(original_data, decompressed)

    def test_lzw_compression_and_decompression(self):
        original_data = b"Ini adalah data untuk pengujian kompresi LZW yang sedikit lebih panjang."
        compressed = compress_lzw(original_data)
        decompressed = decompress_lzw(compressed)
        self.assertEqual(original_data, decompressed)

if __name__ == '__main__':
    unittest.main()