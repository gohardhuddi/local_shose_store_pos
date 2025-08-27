import 'package:floor/floor.dart';

import '../entities/inventory_movement.dart';

@dao
abstract class InventoryMovementDao {
  @insert
  Future<void> insertMovement(InventoryMovement m);

  @Query(
    'SELECT movement_id FROM inventory_movements WHERE movement_id = :id LIMIT 1',
  )
  Future<String?> findExisting(String id);

  @Query(
    'SELECT * FROM inventory_movements WHERE movement_id = :id LIMIT 1',
  )
  Future<InventoryMovement?> findByMovementId(String id);

  @Query('SELECT * FROM inventory_movements WHERE is_synced = 0')
  Future<List<InventoryMovement>> findUnsynced();

  @Query('UPDATE inventory_movements SET is_synced = 1 WHERE movement_id = :id')
  Future<void> markSynced(String id);
}
