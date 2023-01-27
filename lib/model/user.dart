import 'package:check_conduit/model/bankoperation.dart';
import 'package:check_conduit/model/history.dart';
import 'package:check_conduit/model/operation_category.dart';
import 'package:conduit/conduit.dart';

class User extends ManagedObject<_User> implements _User {}

class _User {
  @primaryKey
  int? id;

  @Column(unique: true, indexed: true)
  String? userName;

  @Column(unique: true, indexed: true)
  String? email;

  @Serialize(input: true, output: true)
  String? password;

  @Column(nullable: true)
  String? accessToken;

  @Column(nullable: true)
  String? refreshToken;

  @Column(omitByDefault: true)
  String? salt;

  @Column(omitByDefault: true)
  String? hashPassword;
  ManagedSet<OperationCategory>? categoriesList;
  ManagedSet<BankOperation>? operationList;
  ManagedSet<History>? historiesList;
}

