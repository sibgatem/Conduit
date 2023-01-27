import 'package:check_conduit/model/user.dart';
import 'package:conduit/conduit.dart';
import 'package:check_conduit/model/operation_category.dart';

class BankOperation extends ManagedObject<_BankOperation> implements _BankOperation {}

class _BankOperation{
  @primaryKey
  int? id;
  String? name;
  String? description;
  DateTime? date;
  double? sum;
  @Relate (#operationList, isRequired: true, onDelete: DeleteRule.cascade)
  OperationCategory? operationCategory;
  @Relate(#operationList, isRequired: true, onDelete: DeleteRule.cascade)
  User? user;
  @Column(defaultValue: 'false', omitByDefault: true)
  bool? isDeleted;

}

