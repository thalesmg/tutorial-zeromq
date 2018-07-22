import zmq

context = zmq.Context()
socket = context.socket(zmq.REQ)
socket.connect("ipc://boom")

socket.send_string("Olá.")
print("Voltou um: ", socket.recv_string())
