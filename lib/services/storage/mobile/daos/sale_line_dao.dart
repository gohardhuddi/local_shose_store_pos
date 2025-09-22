import 'package:floor/floor.dart';

import '../entities/sale_line.dart';

@dao
abstract class SaleLineDao {
  @Query('SELECT * FROM sale_lines WHERE sale_id = :saleId')
  Future<List<SaleLine>> getLinesForSale(String saleId);

  @Query('SELECT * FROM sale_lines WHERE sale_line_id = :id')
  Future<SaleLine?> findSaleLineById(String id);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSaleLine(SaleLine line);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSaleLines(List<SaleLine> lines);

  @update
  Future<void> updateSaleLine(SaleLine line);

  @delete
  Future<void> deleteSaleLine(SaleLine line);

  @Query('DELETE FROM sale_lines WHERE sale_id = :saleId')
  Future<void> clearLinesForSale(String saleId);
}
