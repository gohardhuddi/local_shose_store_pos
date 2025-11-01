import 'package:floor/floor.dart';

import '../entities/return_entity.dart';
import '../entities/return_line.dart';

@dao
abstract class ReturnDao {
  // Insert the main return record
  @insert
  Future<void> insertReturn(ReturnEntity entity);

  // ✅ Add missing @insert annotation here
  @insert
  Future<void> insertReturnLine(ReturnLine line);

  // Transaction for inserting both return header and its lines together
  @transaction
  Future<void> insertReturnAndLines(
    ReturnEntity ret,
    List<ReturnLine> lines,
  ) async {
    await insertReturn(ret);
    for (final line in lines) {
      await insertReturnLine(line);
    }
  }
}
