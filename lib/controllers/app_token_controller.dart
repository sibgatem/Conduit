import 'dart:async';
import 'dart:io';
import 'package:conduit/conduit.dart';
import 'package:check_conduit/utils/app_response.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import '../utils/app_const.dart';

class AppTokenController extends Controller {
  @override
  FutureOr<RequestOrResponse?> handle(Request request){
    try{
      final header = request.raw.headers.value(HttpHeaders.authorizationHeader);
      final token = const AuthorizationBearerParser().parse(header);
      final jwtClaim = verifyJwtHS256Signature(token?? '', AppConst.secretKey);
      jwtClaim.validate();
      return request;
    } on JwtException catch (e){
      return AppResponse.serverError(e, message: e.message);
    }
  }
}