import 'package:grpc/grpc.dart';
import 'package:fixnum/fixnum.dart';

import '../src/generated/triangel.pbgrpc.dart';

class GrpcClient {
  GrpcClient._();

  static final GrpcClient instance = GrpcClient._();

  ClientChannel? _channel;
  String? _authToken;

  AuthServiceClient? _auth;
  DocumentConfigServiceClient? _documentConfig;
  DocumentsServiceClient? _documents;
  DocumentServiceClient? _document;
  DeleteDocumentServiceClient? _deleteDocument;
  SendDocumentServiceClient? _sendDocument;
  TaetigkeitServiceClient? _taetigkeit;
  ZeiteintraegeServiceClient? _zeiteintraege;
  ZeiteintragServiceClient? _zeiteintrag;
  PasswordChangeServiceClient? _passwordChange;

  bool get isConnected => _channel != null;

  Future<void> connect({
    String host = 'allebescheuert.de',
    int port = 50051,
    bool useTls = true,
  }) async {
    await disconnect();
    final channel = ClientChannel(
      host,
      port: port,
      options: ChannelOptions(
        credentials: const ChannelCredentials.secure(),
      ),
    );
    _channel = channel;
    _auth = AuthServiceClient(channel);
    _documentConfig = DocumentConfigServiceClient(channel);
    _documents = DocumentsServiceClient(channel);
    _document = DocumentServiceClient(channel);
    _deleteDocument = DeleteDocumentServiceClient(channel);
    _sendDocument = SendDocumentServiceClient(channel);
    _taetigkeit = TaetigkeitServiceClient(channel);
    _zeiteintraege = ZeiteintraegeServiceClient(channel);
    _zeiteintrag = ZeiteintragServiceClient(channel);
    _passwordChange = PasswordChangeServiceClient(channel);
  }

  Future<void> disconnect() async {
    await _channel?.shutdown();
    _channel = null;
    _authToken = null;
    _auth = null;
    _documentConfig = null;
    _documents = null;
    _document = null;
    _deleteDocument = null;
    _sendDocument = null;
    _taetigkeit = null;
    _zeiteintraege = null;
    _zeiteintrag = null;
    _passwordChange = null;
  }
  
  void setAuthToken(String token) => _authToken = token;

  String? get authToken => _authToken;

  CallOptions _opts() {
    final token = _authToken;
    return token == null || token.isEmpty
        ? CallOptions()
        : CallOptions(metadata: {'authorization': 'Bearer $token'});
  }

  T _use<T>(T? stub, String name) {
    if (stub == null) {
      throw StateError('GrpcClient is not connected. Call connect() first.');
    }
    return stub;
  }

  Future<LoginReply> login(String username, String password) =>
      _use(_auth, 'login')
          .login(LoginRequest()..username = username..password = password,
              options: _opts());

  Future<DocumentConfigReply> getDocumentConfig() =>
      _use(_documentConfig, 'getDocumentConfig')
          .getDocumentConfig(DocumentConfigRequest(), options: _opts());

  Future<DocumentsReply> getDocuments(Int64 klientid) =>
      _use(_documents, 'getDocuments')
          .getDocuments(DocumentsRequest()..klientid = klientid,
              options: _opts());

  Future<DocumentReply> getDocument(Dokument dokument) =>
      _use(_document, 'getDocument')
          .getDocument(DocumentRequest()..dokument = dokument,
              options: _opts());

  Future<DeleteDocumentReply> deleteDocument(Dokument dokument) =>
      _use(_deleteDocument, 'deleteDocument')
          .deleteDocument(DeleteDocumentRequest()..dokument = dokument,
              options: _opts());

  Future<SendDocumentReply> sendDocument(Dokument dokument, List<int> file) =>
      _use(_sendDocument, 'sendDocument')
          .sendDocument(SendDocumentRequest()
            ..dokument = dokument
            ..file = file, options: _opts());

  Future<TaetigkeitReply> getTaetigkeiten() =>
      _use(_taetigkeit, 'taetigkeit')
          .taetigkeit(TaetigkeitRequest(), options: _opts());

  Future<ZeiteintraegeReply> getZeiteintraege(Datum datum) =>
      _use(_zeiteintraege, 'zeiteintraege')
          .zeiteintraege(ZeiteintraegeRequest()..zeiteintragdatum = datum,
              options: _opts());

  Future<ZeiteintragReply> saveZeiteintrag(Zeiteintrag zeiteintrag, int operation) =>
      _use(_zeiteintrag, 'zeiteintrag')
          .zeiteintrag(ZeiteintragRequest()
            ..zeiteintrag = zeiteintrag
            ..operation = operation,
              options: _opts());

  Future<PasswordChangeReply> changePassword(
    String oldPassword,
    String newPassword,
  ) =>
      _use(_passwordChange, 'passwordChange').passwordChange(
          PasswordChangeRequest()
            ..oldPassword = oldPassword
            ..newPassword = newPassword,
          options: _opts());
}