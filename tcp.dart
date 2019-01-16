import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:mirrors';

Socket socket;

void main() async {
  socket = await Socket.connect("localhost", 3101);

  socket.listen(onData, onError: onError, onDone: onDone, cancelOnError: true);

  var auth =
      '{"mid":123, "room_id":"live://1000", "platform":"web", "accepts":[1000,1001,1002]}';

  var authBytes = auth.codeUnits;

  var headerLen = 16;
  var packgeLen = authBytes.length + headerLen;

  var message = Uint8List(headerLen);
  var protoBuffer = ByteData.view(message.buffer);

  var offset = 0;
  protoBuffer.setInt32(offset, packgeLen);
  offset += 4;
  protoBuffer.setInt16(offset, headerLen);
  offset += 2;
  protoBuffer.setInt16(offset, 1);
  offset += 2;
  protoBuffer.setInt32(offset, 7);
  offset += 4;
  protoBuffer.setInt32(offset, 1);
  offset += 4;

  socket.add(message);
  socket.add(authBytes);

  sleep(const Duration(seconds: 5));
}

void onData(data) {
  // List<int> header;

  // List.copyRange(header, 16, data);

  // var headerData = ByteData.view(Int8List.fromList(header).buffer);

  // var offset = 0;
  // var packageLen = headerData.getInt32(offset);
  // offset += 4;
  // var headerLen = headerData.getInt16(offset);
  // offset += 2;
  // var ver = headerData.getInt16(offset);
  // offset += 2;
  // var opretion = headerData.getInt32(offset);
  // offset += 4;

  // print(packageLen);
  // print(headerLen);
  // print(ver);
  // print(opretion);

  print(new String.fromCharCodes(data, 16));
}

void onError(error, StackTrace trace) {
  print(error);
}

//
void onDone() {
  print("done");
  socket.close();
  socket.destroy();
  exit(0);
}

getTypeName(dynamic obj) {
  return reflect(obj).type.reflectedType.toString();
}
