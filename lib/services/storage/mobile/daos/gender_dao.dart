import 'package:floor/floor.dart';

import '../entities/gender.dart';

@dao
abstract class GenderDao {
  @insert
  Future<void> insertGender(Gender g);

  @update
  Future<int> updateGender(Gender g);

  @delete
  Future<void> deleteGender(Gender g);

  @Query('SELECT * FROM genders WHERE gender_id = :id LIMIT 1')
  Future<Gender?> findById(String id);

  @Query('SELECT * FROM genders WHERE gender_name = :name LIMIT 1')
  Future<Gender?> findByName(String name);

  @Query('SELECT * FROM genders')
  Future<List<Gender>> all();

  @Query('SELECT * FROM genders WHERE is_active = 1')
  Future<List<Gender>> findActive();

  @Query('SELECT * FROM genders WHERE is_synced = 0')
  Future<List<Gender>> findUnsynced();

  @Query('UPDATE genders SET is_synced = 1 WHERE gender_id = :id')
  Future<void> markSynced(String id);

  @Query(
    'UPDATE genders SET is_active = :active, updated_at = :updatedAt WHERE gender_id = :id',
  )
  Future<void> setActive(String id, int active, String updatedAt);
}
