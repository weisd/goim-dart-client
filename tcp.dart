import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:mirrors';
import 'dart:convert';

const rawHeaderLen = 16;
const packetOffset = 0;
const headerOffset = 4;
const verOffset = 6;
const opOffset = 8;
const seqOffset = 12;

// OpHeartbeat heartbeat
const OpHeartbeat = 2;
// OpHeartbeatReply heartbeat reply
const OpHeartbeatReply = 3;
// OpSendMsg send message.
const OpSendMsg = 4;
// OpSendMsgReply  send message reply
const OpSendMsgReply = 5;
// OpAuth auth connnect
const OpAuth = 7;
// OpAuthReply auth connect reply
const OpAuthReply = 8;
// OpRaw raw message
const OpRaw = 9;

const intervalTimeout = const Duration(seconds: 3);

Socket socket;
Timer timer;

void main() async {
  socket = await Socket.connect("localhost", 3101);

  socket.listen(onData, onError: onError, onDone: onDone, cancelOnError: true);

  var auth =
      '{"mid":123, "room_id":"live://1000", "platform":"web", "accepts":[1000,1001,1002]}';

  sendMsg(OpAuth, auth);
  sleep(const Duration(seconds: 5));
}

void onData(data) {
  var buf = Uint8List.fromList(data).buffer;

  var byteData = buf.asByteData();

  var packetLen = byteData.getInt32(packetOffset);
  var headerLen = byteData.getInt16(headerOffset);
  // var ver = byteData.getInt16(verOffset);
  var op = byteData.getInt32(opOffset);
  // var seq = byteData.getInt32(seqOffset);

  switch (op) {
    case OpAuthReply: // auth rev
      // todo send heartbeat
      sendMsg(OpHeartbeat, null);

      timer = Timer.periodic(intervalTimeout, (Timer t) {
        heartbeat();
      });

      break;
    case OpHeartbeatReply: // heartbeat rev
      print("OpHeartbeatReply");

      break;
    case OpRaw: // raw
      for (var offset = rawHeaderLen;
          offset < data.length;
          offset += packetLen) {
        packetLen = byteData.getInt32(offset);
        headerLen = byteData.getInt16(offset + headerOffset);
        // ver = byteData.getInt16(verOffset);
        op = byteData.getInt32(offset + opOffset);
        // seq = byteData.getInt32(seqOffset);

        print(packetLen);
        print(headerLen);
        print(offset + headerLen);
        print(offset + packetLen);

        messageReceived((new String.fromCharCodes(
            data.sublist(offset + headerLen, offset + packetLen))));
      }
      break;
    default:
      // print("default");
      print(op);
      print(packetLen);
      print(headerLen);

      print(packetLen - headerLen);

      // if (packetLen - headerLen > data.length) {
      print(byteData.lengthInBytes);
      // }

      messageReceived(
          (new String.fromCharCodes(data.sublist(headerLen, packetLen))));
  }
}

void messageReceived(String msg) {
  print(msg);
  var data = jsonDecode(msg);
  print(data);
}

void onError(error, StackTrace trace) {
  print(error);
}

void onDone() {
  if (socket != null) {
    socket.close();
    socket.destroy();
  }

  if (timer != null) {
    timer.cancel();
  }
}

getTypeName(dynamic obj) {
  return reflect(obj).type.reflectedType.toString();
}

void heartbeat() {
  sendMsg(OpHeartbeat, null);
}

void sendMsg(int op, String msg) {
  var packgeLen = rawHeaderLen;
  var body = null;
  if (msg != null) {
    body = msg.codeUnits;
    packgeLen = body.length + rawHeaderLen;
  }

  var message = Uint8List(rawHeaderLen);
  var byteData = ByteData.view(message.buffer);

  byteData.setInt32(packetOffset, packgeLen);
  byteData.setInt16(headerOffset, rawHeaderLen);
  byteData.setInt16(verOffset, 1);
  byteData.setInt32(opOffset, op);
  byteData.setInt32(seqOffset, 1);

  socket.add(message);
  if (msg != null) {
    socket.add(body);
  }
}
