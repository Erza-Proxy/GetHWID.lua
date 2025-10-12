from flask import Flask, request, Response
import os

app = Flask(__name__)

BASE_DIR = '/home/Erza/mysite/ErzaFiles/'

# Map version names to Lua files
VERSION_MAP = {
    'v1': BASE_DIR + 'v1proxy.lua',
    'v2': BASE_DIR + 'v2proxy.lua',
    'v3': BASE_DIR + 'v3proxy.lua',
    'mp': BASE_DIR + 'mobileproxy.lua',
    'betacp': BASE_DIR + 'betacp.lua',
    'betatest': BASE_DIR + 'betatest.lua',
}

@app.route('/get_lua_file')
def get_lua_file():
    version = request.args.get('version')
    ua = request.headers.get('User-Agent', '')

    # Debug logs
    print(f"[DEBUG] Request for version: {version}, User-Agent: {ua}")

    if ua == "ErzaProxyOnTop" and version in VERSION_MAP:
        file_path = VERSION_MAP[version]
        if not os.path.exists(file_path):
            print(f"[DEBUG] File not found for version: {version}")
            return "File not found", 404
        with open(file_path, 'r') as f:
            content = f.read()
            print(f"[DEBUG] Serving file {file_path}, length: {len(content)}")
            return Response(content, content_type='text/plain')

    print(f"[DEBUG] Unauthorized access attempt for version: {version} with User-Agent: {ua}")
    return "Unauthorized", 403

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
