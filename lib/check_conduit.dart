import 'dart:io';
import 'package:check_conduit/controllers/app_auth_controller.dart';
import 'package:check_conduit/controllers/app_history_controller.dart';
import 'package:check_conduit/controllers/app_operation.controller.dart';
import 'package:check_conduit/controllers/app_operation_category_contoller.dart';
import 'package:conduit/conduit.dart';

import 'package:check_conduit/check_conduit.dart';
import 'package:check_conduit/model/bankoperation.dart';
import 'package:check_conduit/model/operation_category.dart';
import 'package:check_conduit/model/user.dart';
import 'package:check_conduit/model/history.dart';

import 'controllers/app_token_controller.dart';
import 'controllers/app_user_controller.dart';

class AppService extends ApplicationChannel {
  late final ManagedContext managedContext;

  @override
  Future prepare() {
    final persistentStore = _initDatabase();

    managedContext = ManagedContext(
        ManagedDataModel.fromCurrentMirrorSystem(), persistentStore);
    return super.prepare();
  }

  @override
  Controller get entryPoint => Router()
    ..route('token/[:refresh]').link(
      () => AppAuthController(managedContext),
    )
    ..route('user')
        .link(AppTokenController.new)!
        .link(() => AppUserController(managedContext))
    ..route('category[/:id]')
        .link(AppTokenController.new)!
        .link(() => AppCategoryController(managedContext))
    ..route('operation[/:id]')
        .link(AppTokenController.new)!
        .link(() => AppOperationController(managedContext))
    ..route('history')
        .link(AppTokenController.new)!
        .link(() => AppHistoryController(managedContext));
  PersistentStore _initDatabase() {
    final username = Platform.environment['DB_USERNAME'] ?? 'postgres';
    final password = Platform.environment['DB_PASSWORD'] ?? '123';
    final host = Platform.environment['DB_HOST'] ?? '127.0.0.1';
    final port = int.parse(Platform.environment['DB_PORT'] ?? '5432');
    final databaseName = Platform.environment['DB_NAME'] ?? 'postgres';
    return PostgreSQLPersistentStore(
        username, password, host, port, databaseName);
  }
}
