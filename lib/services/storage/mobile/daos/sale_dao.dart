import 'package:floor/floor.dart';

import '../entities/sale.dart';

@dao
abstract class SaleDao {
  @Query('SELECT * FROM sales ORDER BY date_time DESC')
  Future<List<Sale>> getAllSales();

  @Query('SELECT * FROM sales WHERE sale_id = :id')
  Future<Sale?> findSaleById(String id);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSale(Sale sale);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSales(List<Sale> sales);

  @update
  Future<void> updateSale(Sale sale);

  @delete
  Future<void> deleteSale(Sale sale);

  @Query('DELETE FROM sales')
  Future<void> clearSales();
}
