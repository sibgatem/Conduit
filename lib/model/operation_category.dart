import 'package:check_conduit/model/user.dart';
import 'package:conduit/conduit.dart';
import 'package:check_conduit/model/bankoperation.dart';

class OperationCategory extends ManagedObject<_OperationCategory>
    implements _OperationCategory {}

class _OperationCategory {
  @primaryKey
  int? id;
  String? name;
  @Relate(#categoriesList, isRequired: true, onDelete: DeleteRule.cascade)
  User? user;
  @Column(defaultValue: 'false', omitByDefault: true)
  bool? isDeleted;
  ManagedSet<BankOperation>? operationList;
}
