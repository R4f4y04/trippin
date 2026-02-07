import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'split_type.g.dart';

@HiveType(typeId: 3)
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum SplitType {
  @HiveField(0)
  equal,
}
