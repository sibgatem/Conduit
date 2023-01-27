import 'package:check_conduit/model/user.dart';
import 'package:conduit/conduit.dart';

class History extends ManagedObject<_History> implements _History {}

class _History {
  @primaryKey
  int? id;
  @Column()
  String? tableName;
  @Column()
  String? description;
  @Column()
  DateTime? dateCreated;
  @Relate(#historiesList, isRequired: true, onDelete: DeleteRule.cascade)
  User? user;
}
