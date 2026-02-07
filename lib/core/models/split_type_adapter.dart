import 'package:hive/hive.dart';

import 'split_type.dart';

class SplitTypeAdapter extends TypeAdapter<SplitType> {
  @override
  final int typeId = 3;

  @override
  SplitType read(BinaryReader reader) {
    final value = reader.readByte();
    switch (value) {
      case 0:
        return SplitType.equal;
      default:
        return SplitType.equal;
    }
  }

  @override
  void write(BinaryWriter writer, SplitType obj) {
    switch (obj) {
      case SplitType.equal:
        writer.writeByte(0);
    }
  }
}
