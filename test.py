import socket
import threading
import random
import time
import string


def random_data_generator(length=16):
    return "".join(
        random.choices(string.ascii_letters + string.digits, k=length)
    ).encode("utf-8")


def handle_client(client_socket, addr):
    print(f"[+] Connection from {addr}")

    def send_random_data():
        while True:
            try:
                data = random_data_generator()
                client_socket.sendall(data)
                time.sleep(2)  # Send random data every 2 seconds
            except Exception:
                break

    sender_thread = threading.Thread(target=send_random_data, daemon=True)
    sender_thread.start()

    try:
        while True:
            received = client_socket.recv(4096)
            if not received:
                break
            print(f"[{addr}] Received: {received}")
            client_socket.sendall(received)  # Echo back
    except Exception as e:
        print(f"[-] Exception with {addr}: {e}")
    finally:
        print(f"[-] Connection closed: {addr}")
        client_socket.close()


def start_server(host="0.0.0.0", port=12345):
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind((host, port))
    server.listen(5)
    print(f"[*] Listening on {host}:{port}")

    try:
        while True:
            client_sock, client_addr = server.accept()
            client_thread = threading.Thread(
                target=handle_client, args=(client_sock, client_addr), daemon=True
            )
            client_thread.start()
    except KeyboardInterrupt:
        print("\n[*] Server shutting down.")
    finally:
        server.close()


if __name__ == "__main__":
    start_server()
