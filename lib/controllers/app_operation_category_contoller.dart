import 'dart:io';
import 'package:check_conduit/controllers/app_history_controller.dart';
import 'package:check_conduit/model/history.dart';
import 'package:check_conduit/model/model_response.dart';
import 'package:check_conduit/model/operation_category.dart';
import 'package:check_conduit/model/user.dart';
import 'package:check_conduit/utils/app_response.dart';
import 'package:check_conduit/utils/app_utils.dart';
import 'package:conduit/conduit.dart';

class AppCategoryController extends ResourceController {
  AppCategoryController(this.managedContext);
  final ManagedContext managedContext;
  @Operation.put()
  Future<Response> createCategory(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.body() OperationCategory operationCategory) async {
    try {
      final user_id = AppUtils.getIdFromHeader(header);
      final user = await managedContext.fetchObjectWithID<User>(user_id);
      final qCreateCategory = Query<OperationCategory>(managedContext)
        ..values.name = operationCategory.name
        ..values.user!.id = user_id;
      final createdCategory = await qCreateCategory.insert();
      final qCategory = await (Query<OperationCategory>(managedContext)
            ..where((category) => category.id).equalTo(createdCategory.id))
          .fetchOne();
      AppHistoryController(managedContext).createRecord(
          model: History()
            ..user = user
            ..description =
                AppHistoryController.createDescription('OperationCategory')
            ..tableName = 'OperationCategory');
      return Response.ok(createdCategory);
    } catch (error) {
      return AppResponse.serverError(error,
          message: 'Ошибка при создании категории');
    }
  }

  @Operation.get()
  Future<Response> getCategory(
    @Bind.header(HttpHeaders.authorizationHeader) String header, {
    @Bind.query('id') int? id,
    @Bind.query('filter') int? filter,
    @Bind.query('search') String? search,
    @Bind.query('page') int page = 1,
    @Bind.query('limit') int limit = 10,
  }) async {
    try {
      if (id != null) {
        final qCategories = Query<OperationCategory>(managedContext)
          ..where((category) => category.id).equalTo(id)
          ..join(object: (user) => user.user);
        final category = await qCategories.fetchOne();
        category!.user!
            .removePropertiesFromBackingMap(['refreshToken', 'accessToken']);
        return Response.ok(category);
      } else {
        final idUser = AppUtils.getIdFromHeader(header);

        final qCategories = Query<OperationCategory>(managedContext)
          ..where((a) => a.user?.id).equalTo(idUser)
          ..where((category) => category.name)
              .contains(search ?? '', caseSensitive: false)
          ..offset = (page - 1) * limit
          ..fetchLimit = limit;
        if (filter != null) {
          print('filter: ${filter.toString()}');
          qCategories
              .where((category) => category.isDeleted)
              .equalTo(filter == 1 ? true : false);
        } else {
          print('filter == null');
          qCategories.where((category) => category.isDeleted).equalTo(false);
        }
        final categories = await qCategories.fetch();

        return Response.ok(categories);
      }
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка при выводе категорий');
    }
  }

  @Operation.post()
  Future<Response> updateCategory(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.body() OperationCategory category,
    @Bind.query('id') int idCategory,
  ) async {
    try {
      final idUser = AppUtils.getIdFromHeader(header);
      final user = await managedContext.fetchObjectWithID<User>(idUser);
      final qFindCategory = Query<OperationCategory>(managedContext)
        ..where((category) => category.id).equalTo(idCategory);
      final fCategory = await qFindCategory.fetchOne();

      final qUpdateCategory = Query<OperationCategory>(managedContext)
        ..where((x) => x.id).equalTo(idCategory)
        ..values.name = category.name ?? fCategory!.name;

      await qUpdateCategory.updateOne();

      final newCategory = await qFindCategory.fetchOne();
      AppHistoryController(managedContext).createRecord(
          model: History()
            ..user = user
            ..description =
                AppHistoryController.updateDescription('OperationCategory')
            ..tableName = 'OperaionCategory');
      return Response.ok(newCategory);
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка обновления данных');
    }
  }

  @Operation.delete()
  Future<Response> deleteCategory(
    @Bind.header(HttpHeaders.authorizationHeader) String header, {
    @Bind.query('id') int? id,
  }) async {
    try {
      final idUser = AppUtils.getIdFromHeader(header);
      final user = await managedContext.fetchObjectWithID<User>(idUser);

      final qDeleteCategory = Query<OperationCategory>(managedContext)
        ..where((category) => category.id).equalTo(id)
        ..where((category) => category.user!.id).equalTo(idUser)
        ..join(set: (x) => x.operationList);
      final category = await qDeleteCategory.fetchOne();

      if (category == null) {
        return Response.badRequest(
          body: {"message": "Категория не найдена"},
        );
      }
      if (category.operationList?.isEmpty == true) {
        final qDelete = Query<OperationCategory>(managedContext)
          ..where((x) => x.id).equalTo(id);
        await qDelete.delete();
        AppHistoryController(managedContext).createRecord(
            model: History()
              ..user = user
              ..description =
                  AppHistoryController.deleteDescription('OperationCategory')
              ..tableName = 'OperationCategory');
        return Response.ok(true);
      }

      final qCategory = Query<OperationCategory>(managedContext)
        ..where((x) => x.id).equalTo(id)
        ..values.isDeleted = true;
      final updated = await qCategory.updateOne();
      return Response.ok(qCategory);
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка обновления данных');
    }
  }

  @Operation.post('id')
  Future<Response> backCategory(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.path('id') int id) async {
    try {
      final qUpdate = Query<OperationCategory>(managedContext)
        ..where((x) => x.id).equalTo(id)
        ..values.isDeleted = false;
      final qCategory = await qUpdate.updateOne();
      return Response.ok(qCategory);
    } catch (e) {
      return AppResponse.ok(message: e.toString());
    }
  }
}
