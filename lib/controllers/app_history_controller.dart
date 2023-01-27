import 'package:check_conduit/model/history.dart';
import 'package:conduit/conduit.dart';
import 'package:check_conduit/utils/app_response.dart';


class AppHistoryController extends ResourceController {
  final ManagedContext managedContext;

  AppHistoryController(this.managedContext);

  static String createDescription(String table) =>
      'Добавление в таблицу $table записи';

  static String updateDescription(String table) =>
      'Изменение записи в таблице $table';

  static String deleteDescription(String table) =>
      'Удаление записи в таблице $table';

  void createRecord({required History model}) async {
    final qCreateRecord = Query<History>(managedContext)
      ..values.tableName = model.tableName
      ..values.description = model.description
      ..values.user?.id = model.user!.id
      ..values.dateCreated = DateTime.now();

    await qCreateRecord.insert();
  }

  @Operation.get()
  Future<Response> getRecords() async {
    try {
      final qRecords = Query<History>(managedContext)
        ..join(object: (x) => x.user);
      final records = await qRecords.fetch();
      for(var item in records){
        item.user!.removePropertiesFromBackingMap(['accessToken', 'refreshToken']);
      }
      return Response.ok(records);
    } catch (e) {
      return AppResponse.ok(message: e.toString());
    }
  }
}