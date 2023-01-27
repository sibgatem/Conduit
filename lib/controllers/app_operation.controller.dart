import 'dart:io';
import 'package:check_conduit/controllers/app_history_controller.dart';
import 'package:check_conduit/model/history.dart';
import 'package:check_conduit/model/model_response.dart';
import 'package:check_conduit/model/operation_category.dart';
import 'package:check_conduit/model/bankoperation.dart';
import 'package:check_conduit/model/user.dart';
import 'package:check_conduit/utils/app_response.dart';
import 'package:check_conduit/utils/app_utils.dart';
import 'package:conduit/conduit.dart';

class AppOperationController extends ResourceController {
  AppOperationController(this.managedContext);
  final ManagedContext managedContext;
  @Operation.put()
  Future<Response> createOperation(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.body() BankOperation operation) async {
    try {
      final user_id = AppUtils.getIdFromHeader(header);
      final user = await managedContext.fetchObjectWithID<User>(user_id);
      final qCreateOperation = Query<BankOperation>(managedContext)
        ..values.name = operation.name
        ..values.description = operation.description
        ..values.date = DateTime.now()
        ..values.sum = operation.sum
        ..values.user!.id = user_id
        ..values.operationCategory!.id = operation.operationCategory!.id;
      final createdOperation = await qCreateOperation.insert();
      final qoperation = await (Query<BankOperation>(managedContext)
            ..where((operation) => operation.id).equalTo(createdOperation.id))
          .fetchOne();
      AppHistoryController(managedContext).createRecord(
          model: History()
            ..user = user
            ..description =
                AppHistoryController.createDescription('Operation')
            ..tableName = 'Operation');
      return Response.ok(createdOperation);
    } catch (error) {
      return AppResponse.serverError(error,
          message: 'Ошибка при создании операции');
    }
  }

  @Operation.get()
  Future<Response> getOperation(
    @Bind.header(HttpHeaders.authorizationHeader) String header, {
    @Bind.query('id') int? id,
    @Bind.query('filter') int? filter,
    @Bind.query('search') String? search,
    @Bind.query('page') int page = 1,
    @Bind.query('limit') int limit = 10,
  }) async {
    try {
      if (id != null) {
        final qOperation = Query<BankOperation>(managedContext)
          ..where((operation) => operation.id).equalTo(id)
          ..join(object: (user) => user.user)
          ..join(object: (category) => category.operationCategory);
        final operation = await qOperation.fetchOne();
        operation!.user!
            .removePropertiesFromBackingMap(['refreshToken', 'accessToken']);
        return Response.ok(operation);
      } else {
        final idUser = AppUtils.getIdFromHeader(header);

        final qOperations = Query<BankOperation>(managedContext)
          ..where((a) => a.user?.id).equalTo(idUser)
          ..where((operation) => operation.name)
              .contains(search ?? '', caseSensitive: false)
          ..offset = (page - 1) * limit
          ..fetchLimit = limit;
        if (filter != null) {
          print('filter: ${filter.toString()}');
          qOperations
              .where((operation) => operation.isDeleted)
              .equalTo(filter == 1 ? true : false);
        } else {
          print('filter == null');
          qOperations.where((operation) => operation.isDeleted).equalTo(false);
        }
        final operations = await qOperations.fetch();
        return Response.ok(operations);
      }
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка при выводе операций');
    }
  }

  @Operation.post()
  Future<Response> updateOperation(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.body() BankOperation operation,
    @Bind.query('id') int idOperation,
  ) async {
    try {
      final idUser = AppUtils.getIdFromHeader(header);
      final user = await managedContext.fetchObjectWithID<User>(idUser);
      final qFindOperation = Query<BankOperation>(managedContext)
        ..where((operation) => operation.id).equalTo(idOperation);
      final fOperation = await qFindOperation.fetchOne();

      final qpdateOperation = Query<BankOperation>(managedContext)
        ..where((x) => x.id).equalTo(idOperation)
        ..values.name = operation.name ?? fOperation!.name
        ..values.description = operation.description ?? fOperation!.name
        ..values.sum = operation.sum ?? fOperation!.sum
        ..values.operationCategory!.id = operation.operationCategory!.id ?? fOperation!.operationCategory!.id;
      await qpdateOperation.updateOne();
      final newOperation = await qFindOperation.fetchOne();
      AppHistoryController(managedContext).createRecord(
          model: History()
            ..user = user
            ..description =
                AppHistoryController.updateDescription('Operation')
            ..tableName = 'Operation');
      return Response.ok(operation);
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка изменения данных операции');
    }
  }

  @Operation.delete()
  Future<Response> deleteOperation(
    @Bind.header(HttpHeaders.authorizationHeader) String header, {
    @Bind.query('id') int? id,
  }) async {
    try {
      final idUser = AppUtils.getIdFromHeader(header);
      final user = await managedContext.fetchObjectWithID<User>(idUser);

      final qDeleteOperation = Query<OperationCategory>(managedContext)
        ..where((operation) => operation.id).equalTo(id)
        ..where((operation) => operation.user!.id).equalTo(idUser);
      final operation = await qDeleteOperation.fetchOne();
      if (operation == null) {
        return Response.badRequest(
          body: {"message": "Операция не найдена"},
        );
      }
        final qDelete = Query<BankOperation>(managedContext)
          ..where((x) => x.id).equalTo(id);
        await qDelete.delete();
        AppHistoryController(managedContext).createRecord(
            model: History()
              ..user = user
              ..description =
                  AppHistoryController.deleteDescription('Operation')
              ..tableName = 'Operation');
        return Response.ok(true);
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка при удалении операции');
    }
  }
}
