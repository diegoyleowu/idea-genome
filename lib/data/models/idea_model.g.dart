// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'idea_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IdeaModelAdapter extends TypeAdapter<IdeaModel> {
  @override
  final int typeId = 0;

  @override
  IdeaModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IdeaModel(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      typeIndex: fields[3] as int,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      categoryId: fields[6] as String?,
      tags: (fields[7] as List).cast<String>(),
      linkedIdeaIds: (fields[8] as List).cast<String>(),
      isDeleted: fields[9] as bool,
      syncStatusIndex: fields[10] as int,
      metadata: (fields[11] as Map).cast<String, dynamic>(),
      audioPath: fields[12] as String?,
      imagePaths: (fields[13] as List).cast<String>(),
      videoPath: fields[14] as String?,
      drawingPath: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, IdeaModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.typeIndex)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.categoryId)
      ..writeByte(7)
      ..write(obj.tags)
      ..writeByte(8)
      ..write(obj.linkedIdeaIds)
      ..writeByte(9)
      ..write(obj.isDeleted)
      ..writeByte(10)
      ..write(obj.syncStatusIndex)
      ..writeByte(11)
      ..write(obj.metadata)
      ..writeByte(12)
      ..write(obj.audioPath)
      ..writeByte(13)
      ..write(obj.imagePaths)
      ..writeByte(14)
      ..write(obj.videoPath)
      ..writeByte(15)
      ..write(obj.drawingPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdeaModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
