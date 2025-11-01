import 'package:floor/floor.dart';

import '../entities/return_line.dart';

@dao
abstract class ReturnLineDao {
  @insert
  Future<void> insertReturnLine(ReturnLine line);

  @Query('SELECT * FROM return_lines WHERE return_id = :returnId')
  Future<List<ReturnLine>> getLinesByReturnId(String returnId);
}
