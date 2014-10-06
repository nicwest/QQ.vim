#!/usr/bin/python

import SimpleHTTPServer
import SocketServer
from socket import SHUT_RDWR
import logging
import cgi

import sys


if len(sys.argv) > 2:
    PORT = int(sys.argv[2])
    I = sys.argv[1]
elif len(sys.argv) > 1:
    PORT = int(sys.argv[1])
    I = ""
else:
    PORT = 8123
    I = ""


class Server(SocketServer.TCPServer):

    keep_serving = True
    allow_reuse_address = 1

    def serve_until_dismissed(self):
        while self.keep_serving:
            self.handle_request()
        self.server_close()

    def server_close(self):
        self.socket.close()


class ServerHandler(SimpleHTTPServer.SimpleHTTPRequestHandler):

    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        self.wfile.write(self.path)
        print self.path
        self.server.keep_serving = False

    def log_message(self, format, *args):
        pass

Handler = ServerHandler

httpd = Server(("", PORT), Handler)
httpd.serve_until_dismissed()
