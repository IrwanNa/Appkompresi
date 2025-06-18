import os
import zlib
import time
from io import BytesIO
from flask import Flask, request, jsonify, send_file
from werkzeug.utils import secure_filename

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = 'uploads'
app.config['COMPRESSED_FOLDER'] = 'compressed'
app.config['MAX_CONTENT_LENGTH'] = 50 * 1024 * 1024  # Maximal 50MB

ALLOWED_EXTENSIONS = {'docx', 'pdf', 'pptx', 'txt'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def create_directory(dir_path):
    if not os.path.exists(dir_path):
        os.makedirs(dir_path)

def read_file(file_path):
    with open(file_path, 'rb') as f:
        return f.read()

def write_file(file_path, data):
    with open(file_path, 'wb') as f:
        f.write(data)

### FUNGSI DEFLATE
def compress_deflate(data):
    return zlib.compress(data, level=9)

def decompress_deflate(data):
    return zlib.decompress(data)

### FUNGSI LZW
def compress_lzw(data):
    dict_size = 256
    dictionary = {bytes([i]): i for i in range(dict_size)}
    w = b""
    compressed = []

    for byte in data:
        wc = w + bytes([byte])
        if wc in dictionary:
            w = wc
        else:
            compressed.append(dictionary[w])
            if dict_size < 2**24:  # Batas 3-byte
                dictionary[wc] = dict_size
                dict_size += 1
            w = bytes([byte])
    
    if w:
        compressed.append(dictionary[w])
    
    # Setiap kode diubah menjadi 3-byte big-endian
    return b''.join([code.to_bytes(3, 'big') for code in compressed])

def decompress_lzw(data):
    if len(data) % 3 != 0:
        raise ValueError("Gagal data melebihi batas maksimal.")
    
    compressed = [int.from_bytes(data[i:i+3], 'big') for i in range(0, len(data), 3)]
    dict_size = 256
    dictionary = {i: bytes([i]) for i in range(dict_size)}
    result = bytearray()

    w = bytes([compressed[0]])
    result.extend(w)

    for k in compressed[1:]:
        if k in dictionary:
            entry = dictionary[k]
        elif k == dict_size:
            entry = w + bytes([w[0]])
        else:
            raise ValueError('Gagal mengkompresi data')
        
        result.extend(entry)
        if dict_size < 2**24:
            dictionary[dict_size] = w + bytes([entry[0]])
            dict_size += 1
        w = entry

    return bytes(result)

### MODIFIKASI PADA ENDPOINT /compress
@app.route('/compress', methods=['POST'])
def handle_compression():
    if 'file' not in request.files:
        return jsonify({'error': 'No file uploaded'}), 400

    file = request.files['file']
    method = request.form.get('method', 'deflate').lower()

    if file.filename == '' or not allowed_file(file.filename):
        return jsonify({'error': 'Invalid file'}), 400

    try:
        # Simpan file asli
        create_directory(app.config['UPLOAD_FOLDER'])
        original_filename = secure_filename(file.filename)
        original_path = os.path.join(app.config['UPLOAD_FOLDER'], original_filename)
        file.save(original_path)

        original_data = read_file(original_path)
        original_size = len(original_data)

        # Pilih metode kompresi dan tambahkan header 4-byte sesuai metode
        start_time = time.time()
        if method == 'deflate':
            header = b"DFLT"
            compressed_body = compress_deflate(original_data)
        elif method == 'lzw':
            header = b"LZW "
            compressed_body = compress_lzw(original_data)
        else:
            return jsonify({'error': 'Invalid compression method'}), 400

        compressed_data = header + compressed_body
        compress_time = time.time() - start_time

        # Simpan hasil kompresi
        create_directory(app.config['COMPRESSED_FOLDER'])
        compressed_filename = f"compressed_{original_filename}"
        compressed_path = os.path.join(app.config['COMPRESSED_FOLDER'], compressed_filename)
        write_file(compressed_path, compressed_data)

        # Uji dekompresi untuk memastikan integritas data
        start_time_decompress = time.time()
        # Ambil header dari data yang telah dikompres
        method_header = compressed_data[:4]
        body = compressed_data[4:]
        if method_header == b"DFLT":
            decompressed_data = decompress_deflate(body)
        elif method_header == b"LZW ":
            decompressed_data = decompress_lzw(body)
        else:
            raise ValueError("Unknown compression method header")
        decompress_time = time.time() - start_time_decompress

        if decompressed_data != original_data:
            return jsonify({'error': 'Decompression failed'}), 500

        return jsonify({
            'original_size': original_size,
            'compressed_size': len(compressed_data),
            'compression_ratio': ((original_size - len(compressed_data)) / original_size) * 100,
            'compress_time': compress_time,
            'decompress_time': decompress_time,
            'compressed_file': compressed_filename,
            'compression_method': method
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

    finally:
        if os.path.exists(original_path):
            os.remove(original_path)

### MODIFIKASI PADA ENDPOINT /download
@app.route('/download/<filename>')
def download_file(filename):
    try:
        safe_filename = secure_filename(filename)
        compressed_path = os.path.join(app.config['COMPRESSED_FOLDER'], safe_filename)

        if not os.path.isfile(compressed_path):
            app.logger.error(f"File not found: {compressed_path}")
            return jsonify({'error': 'File not found'}), 404

        compressed_data = read_file(compressed_path)

        # Baca header 4-byte untuk mengetahui metode kompresi
        if len(compressed_data) < 4:
            raise ValueError("File compressed data invalid (no header found)")
        method_header = compressed_data[:4]
        body = compressed_data[4:]

        if method_header == b"DFLT":
            try:
                decompressed_data = decompress_deflate(body)
            except Exception as e:
                app.logger.error(f"Deflate decompression error: {str(e)}")
                return jsonify({'error': f'Deflate decompression error: {str(e)}'}), 500
        elif method_header == b"LZW ":
            try:
                decompressed_data = decompress_lzw(body)
            except Exception as e:
                app.logger.error(f"LZW decompression error: {str(e)}")
                return jsonify({'error': f'LZW decompression error: {str(e)}'}), 500
        else:
            return jsonify({'error': 'Unknown compression method header'}), 500

        file_stream = BytesIO(decompressed_data)
        file_stream.seek(0)

        original_filename = safe_filename.replace("compressed_", "")
        decompressed_filename = f"decompressed_{original_filename}"

        return send_file(
            file_stream,
            as_attachment=True,
            download_name=decompressed_filename,
            mimetype='application/octet-stream'
        )

    except Exception as e:
        app.logger.error(f"Download error: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)