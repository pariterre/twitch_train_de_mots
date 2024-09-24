import os
import http.server
import ssl
from socket import gethostname

from OpenSSL import crypto


CERT_FILE = "public.crt"
KEY_FILE = "private.key"

def create_symbolic_links():
    # Create symbolic links to configuration and video_component built folder
    if not os.path.exists("configuration"):
        os.makedirs("configuration")
        
    if not os.path.exists("video_component"):
        os.symlink("../frontends/video_component/build/web", "video_component")
    

def create_self_signed_cert(cert_dir):
    """
    If datacard.crt and datacard.key don't exist in cert_dir, create a new
    self-signed cert and keypair and write them into that directory.
    """

    if not os.path.exists(cert_dir):
        os.makedirs(cert_dir)

    if not os.path.exists(os.path.join(cert_dir, CERT_FILE)) or not os.path.exists(os.path.join(cert_dir, KEY_FILE)):
            
        # create a key pair
        k = crypto.PKey()
        k.generate_key(crypto.TYPE_RSA, 2048)

        # create a self-signed cert
        cert = crypto.X509()
        cert.get_subject().C = "QC"
        cert.get_subject().ST = "Montreal"
        cert.get_subject().L = "Montreal"
        cert.get_subject().O = "Pariterre"
        cert.get_subject().OU = "Pariterre"
        cert.get_subject().CN = gethostname()
        cert.set_serial_number(1000)
        cert.gmtime_adj_notBefore(0)
        cert.gmtime_adj_notAfter(10*365*24*60*60)
        cert.set_issuer(cert.get_subject())
        cert.set_pubkey(k)
        cert.sign(k, 'sha1')

        open(os.path.join(cert_dir, CERT_FILE), "wb").write(
            crypto.dump_certificate(crypto.FILETYPE_PEM, cert))
        open(os.path.join(cert_dir, KEY_FILE), "wb").write(
            crypto.dump_privatekey(crypto.FILETYPE_PEM, k))



class MyHandler(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        print(post_data.decode('utf-8'))

    def do_OPTIONS(self):
        # Handle the OPTIONS request for CORS preflight
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

def main(cert_dir="certs"):
    server_address = ('localhost', 8080)
    httpd = http.server.HTTPServer(server_address, MyHandler)

    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    # To generate the certificates:
    # openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout key.pem -out cert.pem
    context.load_cert_chain(certfile=os.path.join(cert_dir, CERT_FILE), keyfile=os.path.join(cert_dir, KEY_FILE))

    httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
    print("Server running at https://{}:{}".format(server_address[0], server_address[1]))
    httpd.serve_forever()


if __name__ == '__main__':
    create_symbolic_links()
    create_self_signed_cert("certs")
    main()