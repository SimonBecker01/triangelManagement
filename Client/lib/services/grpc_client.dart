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
  CreateUserServiceClient? _createUser;
  GetUsersServiceClient? _getUsers;
  GetRolesServiceClient? _getRoles;
  ChangeUserServiceClient? _changeUser;
  GetRechteKategorienServiceClient? _getRechteKategorien;
  GetRechteGruppeServiceClient? _getRechteGruppe;
  SetRechteServiceClient? _setRechte;
  ChangeKategorieServiceClient? _changeKategorie;
  ChangeGruppeServiceClient? _changeGruppe;
  DeleteKategorieServiceClient? _deleteKategorie;
  DeleteGruppeServiceClient? _deleteGruppe;
  SetNewKategorieServiceClient? _setNewKategorie;
  SetNewGruppeServiceClient? _setNewGruppe;
  ChangeTaetigkeitServiceClient? _changeTaetigkeit;
  DeleteTaetigkeitServiceClient? _deleteTaetigkeit;
  SetNewTaetigkeitServiceClient? _setNewTaetigkeit;
  GetBetreuungenServiceClient? _getBetreuungen;
  EndBetreuungServiceClient? _endBetreuung;
  SetNewBetreuungServiceClient? _setNewBetreuung;
  AuswertungBetreuungServiceClient? _auswertungBetreuung;
  AuswertungBetreuerServiceClient? _auswertungBetreuer;
  AuswertungKlientServiceClient? _auswertungKlient;
  

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
    _createUser = CreateUserServiceClient(channel);
    _getUsers = GetUsersServiceClient(channel);
    _getRoles = GetRolesServiceClient(channel);
    _changeUser = ChangeUserServiceClient(channel);
    _getRechteKategorien = GetRechteKategorienServiceClient(channel);
    _getRechteGruppe = GetRechteGruppeServiceClient(channel);
    _setRechte = SetRechteServiceClient(channel);
    _changeKategorie = ChangeKategorieServiceClient(channel);
    _changeGruppe = ChangeGruppeServiceClient(channel);
    _deleteKategorie = DeleteKategorieServiceClient(channel);
    _deleteGruppe = DeleteGruppeServiceClient(channel);
    _setNewKategorie = SetNewKategorieServiceClient(channel);
    _setNewGruppe = SetNewGruppeServiceClient(channel);
    _changeTaetigkeit = ChangeTaetigkeitServiceClient(channel);
    _deleteTaetigkeit = DeleteTaetigkeitServiceClient(channel);
    _setNewTaetigkeit = SetNewTaetigkeitServiceClient(channel);
    _getBetreuungen = GetBetreuungenServiceClient(channel);
    _endBetreuung = EndBetreuungServiceClient(channel);
    _setNewBetreuung = SetNewBetreuungServiceClient(channel);
    _auswertungBetreuung = AuswertungBetreuungServiceClient(channel);
    _auswertungBetreuer = AuswertungBetreuerServiceClient(channel);
    _auswertungKlient = AuswertungKlientServiceClient(channel);
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
    _createUser = null;
    _getUsers = null;
    _getRoles = null;
    _changeUser = null;
    _getRechteKategorien = null;
    _getRechteGruppe = null;
    _setRechte = null;
    _changeKategorie = null;
    _changeGruppe = null;
    _deleteKategorie = null;
    _deleteGruppe = null;
    _setNewKategorie = null;
    _setNewGruppe = null;
    _changeTaetigkeit = null;
    _deleteTaetigkeit = null;
    _setNewTaetigkeit = null;
    _getBetreuungen = null;
    _endBetreuung = null;
    _setNewBetreuung = null;
    _auswertungBetreuung = null;
    _auswertungBetreuer = null;
    _auswertungKlient = null;
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

  Future<CreateUserReply> createUser(UserObjekt newUser) =>
      _use(_createUser, 'createUser')
          .createUser(CreateUserRequest()
            ..newUser = newUser, options: _opts());

  Future<GetUsersReply> getUsers() =>
      _use(_getUsers, 'getUsers')
          .getUsers(GetUsersRequest(),
              options: _opts());

  Future<GetRolesReply> getRoles() =>
      _use(_getRoles, 'getRoles')
          .getRoles(GetRolesRequest(),
              options: _opts());

  Future<ChangeUserReply> changeUser(UserObjekt changedUser, int forceReset) =>
      _use(_changeUser, 'changeUser')
          .changeUser(ChangeUserRequest()
            ..changedUser = changedUser
            ..forceReset = forceReset
            , options: _opts());

  Future<GetRechteKategorienReply> getRechteKategorien() =>
      _use(_getRechteKategorien, 'getRechteKategorien')
          .getRechteKategorien(GetRechteKategorienRequest()
            , options: _opts());

  Future<GetRechteGruppeReply> getRechteGruppe() =>
      _use(_getRechteGruppe, 'getRechteGruppe')
          .getRechteGruppe(GetRechteGruppeRequest()
            , options: _opts());

  Future<SetRechteReply> setRechte(Int64 rollenId, List<Int64> gruppenId, List<Int64> kategorienId) =>
      _use(_setRechte, 'setRechte')
          .setRechte(SetRechteRequest()
            ..rollenId = rollenId
            //..gruppenId = gruppenId
            //..kategorienId = kategorienId
            , options: _opts());

  Future<ChangeKategorieReply> changeKategorie(IdObjekt kategorie) =>
      _use(_changeKategorie, 'changeKategorie')
          .changeKategorie(ChangeKategorieRequest()
            ..kategorie = kategorie
            , options: _opts());

  Future<ChangeGruppeReply> changeGruppe(IdObjekt gruppe) =>
      _use(_changeGruppe, 'changeKategorie')
          .changeGruppe(ChangeGruppeRequest()
            ..gruppe = gruppe
            , options: _opts());

  Future<DeleteKategorieReply> deleteKategorie(IdObjekt kategorie) =>
      _use(_deleteKategorie, 'deleteKategorie')
          .deleteKategorie(DeleteKategorieRequest()
            ..kategorie = kategorie
            , options: _opts());

  Future<DeleteGruppeReply> deleteGruppe(IdObjekt gruppe) =>
      _use(_deleteGruppe, 'deleteKategorie')
          .deleteGruppe(DeleteGruppeRequest()
            ..gruppe = gruppe
            , options: _opts());

  Future<SetNewKategorieReply> setNewKategorie(IdObjekt kategorie) =>
      _use(_setNewKategorie, 'setNewKategorie')
          .setNewKategorie(SetNewKategorieRequest()
            ..kategorie = kategorie
            , options: _opts());

  Future<SetNewGruppeReply> setNewGruppe(IdObjekt gruppe) =>
      _use(_setNewGruppe, 'setNewKategorie')
          .setNewGruppe(SetNewGruppeRequest()
            ..gruppe = gruppe
            , options: _opts());

  Future<ChangeTaetigkeitReply> changeTaetigkeit(Taetigkeit taetigkeit) =>
      _use(_changeTaetigkeit, 'changeTaetigkeit')
          .changeTaetigkeit(ChangeTaetigkeitRequest()
            ..taetigkeit = taetigkeit
            , options: _opts());

  Future<DeleteTaetigkeitReply> deleteTaetigkeit(Int64 taetigkeitId) =>
      _use(_deleteTaetigkeit, 'deleteTaetigkeit')
          .deleteTaetigkeit(DeleteTaetigkeitRequest()
            ..taetigkeitId = taetigkeitId
            , options: _opts());

  Future<SetNewTaetigkeitReply> setNewTaetigkeit(Taetigkeit taetigkeit) =>
      _use(_setNewTaetigkeit, 'setNewTaetigkeit')
          .setNewTaetigkeit(SetNewTaetigkeitRequest()
            ..taetigkeit = taetigkeit
            , options: _opts());

  Future<GetBetreuungenReply> getBetreuungen() =>
      _use(_getBetreuungen, 'getBetreuungen')
          .getBetreuungen(GetBetreuungenRequest()
            , options: _opts());

  Future<EndBetreuungReply> endBetreuung(Int64 betreuungId) =>
      _use(_endBetreuung, 'endBetreuung')
          .endBetreuung(EndBetreuungRequest()
            ..betreuungId = betreuungId
            , options: _opts());

  Future<SetNewBetreuungReply> setNewBetreuung(Betreuung betreuung) =>
      _use(_setNewBetreuung, 'setNewBetreuung')
          .setNewBetreuung(SetNewBetreuungRequest()
            ..betreuung = betreuung
            , options: _opts());

  Future<AuswertungReply> auswertungBetreuung(Int64 betreuung, Datum monat, bool abrechenbar) =>
      _use(_auswertungBetreuung, 'auswertungBetreuung')
          .auswertungBetreuung(AuswertungBetreuungRequest()
            ..betreuung = betreuung
            ..monat = monat
            ..abrechenbar = abrechenbar
            , options: _opts());

  Future<AuswertungReply> auswertungBetreuer(Int64 betreuer, Datum monat, bool abrechenbar) =>
      _use(_auswertungBetreuer, 'auswertungBetreuer')
          .auswertungBetreuer(AuswertungBetreuerRequest()
            ..betreuer = betreuer
            ..monat = monat
            ..abrechenbar = abrechenbar
            , options: _opts());

  Future<AuswertungReply> auswertungKlient(Int64 klient, Datum monat, bool abrechenbar) =>
      _use(_auswertungKlient, 'auswertungKlient')
          .auswertungKlient(AuswertungKlientRequest()
            ..klient = klient
            ..monat = monat
            ..abrechenbar = abrechenbar
            , options: _opts());
}