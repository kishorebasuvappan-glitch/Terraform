
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

OIDC_DIR = "/workspaces/Terraform/oidc"


class OIDCHandler(SimpleHTTPRequestHandler):
    def translate_path(self, path):
        # Map public /oidc/... URLs to files inside OIDC_DIR.
        if path == "/oidc":
            path = "/"
        elif path.startswith("/oidc/"):
            path = path[len("/oidc"):]

        return super().translate_path(path)

    def guess_type(self, path):
        if (
            path.endswith(".json")
            or path.endswith("jwks")
            or path.endswith("openid-configuration")
        ):
            return "application/json"

        return super().guess_type(path)


server = ThreadingHTTPServer(
    ("0.0.0.0", 8000),
    lambda *args, **kwargs: OIDCHandler(
        *args, directory=OIDC_DIR, **kwargs
    ),
)

print("OIDC server running on port 8000", flush=True)
server.serve_forever()


