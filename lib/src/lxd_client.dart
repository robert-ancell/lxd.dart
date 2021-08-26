import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

import 'http_unix_client.dart';
import 'simplestream_client.dart';

/// General response from lxd.
abstract class _LxdResponse {
  /// Request result. Throws an exception if not a sync result.
  dynamic get result;

  /// Request operation. Throws an exception if not an async result.
  LxdOperation get operation;

  const _LxdResponse();
}

/// Response retuned when a sync request is completed.
class _LxdSyncResponse extends _LxdResponse {
  final int statusCode;

  final String status;

  final dynamic _result;

  @override
  dynamic get result => _result;

  @override
  LxdOperation get operation => throw 'Result is sync';

  _LxdSyncResponse(dynamic result,
      {required this.statusCode, required this.status})
      : _result = result;
}

/// Response retuned when an async request has been started.
class _LxdAsyncResponse extends _LxdResponse {
  final int statusCode;

  final String status;

  final LxdOperation _operation;

  @override
  dynamic get result => throw 'Result is async';

  @override
  LxdOperation get operation => _operation;

  _LxdAsyncResponse(LxdOperation operation,
      {required this.statusCode, required this.status})
      : _operation = operation;
}

/// Response retuned when an error occurred.
class _LxdErrorResponse extends _LxdResponse {
  // Error code.
  final int errorCode;

  /// Error message returned.
  final String error;

  @override
  dynamic get result => throw 'Result is error: $error';

  @override
  LxdOperation get operation => throw 'Result is error: $error';

  const _LxdErrorResponse({required this.errorCode, required this.error});
}

class LxdOperation {
  final DateTime createdAt;
  final String description;
  final String error;
  final String id;
  final String status;
  final int statusCode;
  final DateTime updatedAt;

  LxdOperation(
      {required this.createdAt,
      required this.description,
      required this.error,
      required this.id,
      required this.status,
      required this.statusCode,
      required this.updatedAt});
}

class LxdCpuResources {
  final String architecture;
  final List<String> sockets;

  LxdCpuResources({required this.architecture, required this.sockets});

  @override
  String toString() =>
      'LxdCpuResources(architecture: $architecture, sockets: $sockets)';
}

class LxdMemoryResources {
  final int used;
  final int total;

  LxdMemoryResources({required this.used, required this.total});

  @override
  String toString() => 'LxdMemoryResources(used: $used, total: $total)';
}

class LxdGpuCard {
  LxdGpuCard();

  @override
  String toString() => 'LxdGpuCard()';
}

class LxdNetworkDevice {
  LxdNetworkDevice();

  @override
  String toString() => 'LxdNetworkDevice()';
}

class LxdDisk {
  LxdDisk();

  @override
  String toString() => 'LxdDisk()';
}

class LxdUsbDevice {
  LxdUsbDevice();

  @override
  String toString() => 'LxdUsbDevice()';
}

class LxdPciDevice {
  LxdPciDevice();

  @override
  String toString() => 'LxdPciDevice()';
}

class LxdFirmware {
  final String date;
  final String vendor;
  final String version;

  LxdFirmware(
      {required this.date, required this.vendor, required this.version});

  @override
  String toString() =>
      'LxdFirmware(date: $date, vendor: $vendor, version: $version)';
}

class LxdChassis {
  final String serial;
  final String type;
  final String vendor;
  final String version;

  LxdChassis(
      {required this.serial,
      required this.type,
      required this.vendor,
      required this.version});

  @override
  String toString() =>
      'LxdChassis(serial: $serial, type: $type, vendor: $vendor, version: $version)';
}

class LxdMotherboard {
  final String product;
  final String serial;
  final String vendor;
  final String version;

  LxdMotherboard(
      {required this.product,
      required this.serial,
      required this.vendor,
      required this.version});

  @override
  String toString() =>
      'LxdMotherboard(product: $product, serial: $serial, vendor: $vendor, version: $version)';
}

class LxdSystemResources {
  final String uuid;
  final String vendor;
  final String product;
  final String family;
  final String version;
  final String sku;
  final String serial;
  final String type;
  final LxdFirmware firmware;
  final LxdChassis chassis;
  final LxdMotherboard motherboard;

  LxdSystemResources(
      {required this.uuid,
      required this.vendor,
      required this.product,
      required this.family,
      required this.version,
      required this.sku,
      required this.serial,
      required this.type,
      required this.firmware,
      required this.chassis,
      required this.motherboard});

  @override
  String toString() =>
      'LxdSystemResources(uuid: $uuid, vendor: $vendor, product: $product, family: $family, version: $version, sku: $sku, serial: $serial, type: $type, firmware: $firmware, chassis: $chassis, motherboar: $motherboard)';
}

class LxdResources {
  final LxdCpuResources cpu;
  final LxdMemoryResources memory;
  final List<LxdGpuCard> gpu;
  final List<LxdNetworkDevice> network;
  final List<LxdDisk> storage;
  final List<LxdUsbDevice> usb;
  final List<LxdPciDevice> pci;
  final LxdSystemResources system;

  LxdResources(
      {required this.cpu,
      required this.memory,
      required this.gpu,
      required this.network,
      required this.storage,
      required this.usb,
      required this.pci,
      required this.system});

  @override
  String toString() =>
      'LxdResources(cpu: $cpu, memory: $memory, gpu: $gpu, network: $network, storage: $storage, usb: $usb, pci: $pci, system: $system)';
}

class LxdCertificate {
  final String certificate;
  final String fingerprint;
  final String name;
  final List<String> projects;
  final bool restricted;
  final String type;

  LxdCertificate(
      {required this.certificate,
      required this.fingerprint,
      required this.name,
      required this.projects,
      required this.restricted,
      required this.type});
}

class LxdProject {
  final Map<String, dynamic> config;
  final String description;
  final String name;

  LxdProject(
      {required this.config, required this.description, required this.name});

  @override
  String toString() =>
      "LxdProject(config: $config, description: '$description', name: $name)";
}

class LxdImage {
  final String architecture;
  final bool autoUpdate;
  final bool cached;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String filename;
  final String fingerprint;
  final DateTime lastUsedAt;
  final List<String> profiles;
  final bool public;
  final int size;
  final String type;
  final DateTime uploadedAt;

  LxdImage({
    required this.architecture,
    required this.autoUpdate,
    required this.cached,
    required this.createdAt,
    required this.expiresAt,
    required this.filename,
    required this.fingerprint,
    required this.lastUsedAt,
    required this.profiles,
    required this.public,
    required this.size,
    required this.type,
    required this.uploadedAt,
  });
}

class LxdInstance {
  final String architecture;
  final Map<String, dynamic> config;
  final DateTime createdAt;
  final String description;
  final bool ephemeral;
  final DateTime lastUsedAt;
  final String location;
  final String name;
  final List<String> profiles;
  final bool stateful;
  final String status;
  final int statusCode;
  final String type;

  LxdInstance(
      {required this.architecture,
      required this.config,
      required this.createdAt,
      required this.description,
      required this.ephemeral,
      required this.lastUsedAt,
      required this.location,
      required this.name,
      required this.profiles,
      required this.stateful,
      required this.status,
      required this.statusCode,
      required this.type});

  @override
  String toString() =>
      "LxdInstance(architecture: $architecture, config: $config, createdAt: $createdAt, description: '$description', ephemeral: $ephemeral, lastUsedAt: $lastUsedAt, location: $location, name: $name, profiles: $profiles, stateful: $stateful, status: $status, statusCode: $statusCode, type: $type)";
}

/// Manages a connection to the lxd server.
class LxdClient {
  HttpUnixClient? _client;
  String? _userAgent;
  final String? _socketPath;

  dynamic hostInfo;

  LxdClient({String userAgent = 'lxd.dart', String? socketPath})
      : _userAgent = userAgent,
        _socketPath = socketPath;

  /// Sets the user agent sent in requests to lxd.
  set userAgent(String? value) => _userAgent = value;

  /// Get the current state of the operation with [id].
  Future<LxdOperation> getOperation(String id) async {
    await _connect();
    var response = await _getSync('/1.0/operations/$id');
    return _parseOperation(response);
  }

  /// Wait for the operation with [id] to complete.
  Future<LxdOperation> waitOperation(String id) async {
    await _connect();
    var response = await _getSync('/1.0/operations/$id/wait');
    return _parseOperation(response);
  }

  Future<LxdResources> getResources() async {
    await _connect();
    var data = await _getSync('/1.0/resources');
    var cpuData = data['cpu'];
    var memoryData = data['memory'];
    var systemData = data['system'];
    var firmwareData = systemData['firmware'];
    var chassisData = systemData['chassis'];
    var motherboardData = systemData['motherboard'];
    return LxdResources(
        cpu: LxdCpuResources(
            architecture: cpuData['architecture'], sockets: []), // FIXME
        memory: LxdMemoryResources(
            used: memoryData['used'], total: memoryData['total']),
        gpu: [], // FIXME
        network: [], // FIXME
        storage: [], // FIXME
        usb: [], // FIXME
        pci: [], // FIXME
        system: LxdSystemResources(
            uuid: systemData['uuid'],
            vendor: systemData['vendor'],
            product: systemData['product'],
            family: systemData['family'],
            version: systemData['version'],
            sku: systemData['sku'],
            serial: systemData['serial'],
            type: systemData['type'],
            firmware: LxdFirmware(
                date: firmwareData['date'],
                vendor: firmwareData['vendor'],
                version: firmwareData['version']),
            chassis: LxdChassis(
                serial: chassisData['serial'],
                type: chassisData['type'],
                vendor: chassisData['vendor'],
                version: chassisData['version']),
            motherboard: LxdMotherboard(
                product: motherboardData['product'],
                serial: motherboardData['serial'],
                vendor: motherboardData['vendor'],
                version: motherboardData['version'])));
  }

  Future<List<LxdCertificate>> getCertificates() async {
    var certificatePaths = await _getSync('/1.0/certificates');
    var certificates = <LxdCertificate>[];
    for (var path in certificatePaths) {
      var certificate = await _getSync(path);
      certificates.add(LxdCertificate(
          certificate: certificate['certificate'],
          fingerprint: certificate['fingerprint'],
          name: certificate['name'],
          projects: certificate['projects'],
          restricted: certificate['restricted'],
          type: certificate['type']));
    }
    return certificates;
  }

  Future<List<LxdProject>> getProjects() async {
    var projectPaths = await _getSync('/1.0/projects');
    var projects = <LxdProject>[];
    for (var path in projectPaths) {
      var project = await _getSync(path);
      projects.add(LxdProject(
          config: project['config'],
          description: project['description'],
          name: project['name']));
    }
    return projects;
  }

  Future<List<LxdImage>> getImages({String? project, String? filter}) async {
    await _connect();
    var parameters = <String, String>{};
    if (project != null) {
      parameters['project'] = project;
    }
    if (filter != null) {
      parameters['filter'] = filter;
    }
    var imagePaths = await _getSync('/1.0/images', parameters);
    var images = <LxdImage>[];
    for (var path in imagePaths) {
      images.add(await _getImage(path));
    }
    return images;
  }

  Future<LxdImage> getImage(String fingerprint) async {
    return await _getImage('/1.0/images/$fingerprint');
  }

  Future<LxdImage> _getImage(String path) async {
    var image = await _getSync(path);
    return LxdImage(
        architecture: image['architecture'],
        autoUpdate: image['auto_update'],
        cached: image['cached'],
        createdAt: DateTime.parse(image['created_at']),
        expiresAt: DateTime.parse(image['expires_at']),
        filename: image['filename'],
        fingerprint: image['fingerprint'],
        lastUsedAt: DateTime.parse(image['last_used_at']),
        profiles: image['profiles'].cast<String>(),
        public: image['public'],
        size: image['size'],
        type: image['type'],
        uploadedAt: DateTime.parse(image['uploaded_at']));
  }

  Future<List<LxdInstance>> getInstances() async {
    await _connect();
    var instancePaths = await _getSync('/1.0/instances');
    var instances = <LxdInstance>[];
    for (var path in instancePaths) {
      var instance = await _getSync(path);
      // FIXME: 'devices', 'expanded_config', 'expanded_devices'
      instances.add(LxdInstance(
          architecture: instance['architecture'],
          config: instance['config'],
          createdAt: DateTime.parse(instance['created_at']),
          description: instance['description'],
          ephemeral: instance['ephemeral'],
          lastUsedAt: DateTime.parse(instance['last_used_at']),
          location: instance['location'],
          name: instance['name'],
          profiles: instance['profiles'].cast<String>(),
          stateful: instance['stateful'],
          status: instance['status'],
          statusCode: instance['status_code'],
          type: instance['type']));
    }
    return instances;
  }

  Future<LxdOperation> createInstance(
      {String? architecture,
      String? description,
      String? name,
      required SimplestreamDownloadItem source,
      required String url}) async {
    await _connect();
    var body = {};
    if (architecture != null) {
      body['architecture'] = architecture;
    }
    if (description != null) {
      body['description'] = description;
    }
    if (name != null) {
      body['name'] = name;
    }
    var s = {};
    s['type'] = 'image';
    s['fingerprint'] = source.combinedSquashfsSha256;
    s['protocol'] = 'simplestreams';
    s['server'] = url;
    body['source'] = s;
    return await _postAsync('/1.0/instances', body);
  }

  /// Terminates all active connections. If a client remains unclosed, the Dart process may not terminate.
  void close() {
    _client?.close();
  }

  Future<void> _connect() async {
    hostInfo ??= await _getSync('/1.0');
  }

  /// Get the HTTP client to communicate with lxd.
  Future<HttpUnixClient> _getClient() async {
    if (_client != null) {
      return _client!;
    }

    var socketPath = _socketPath;
    if (socketPath == null) {
      var lxdDir = Platform.environment['LXD_DIR'];
      var snapSocketPath = '/var/snap/lxd/common/lxd/unix.socket';
      if (lxdDir != null) {
        socketPath = lxdDir + '/unix.socket';
      } else if (await File(snapSocketPath).exists()) {
        socketPath = snapSocketPath;
      } else {
        socketPath = '/var/lib/lxd/unix.socket';
      }
    }

    _client = HttpUnixClient(socketPath);
    return _client!;
  }

  /// Does a synchronous request to lxd.
  Future<dynamic> _getSync(String path,
      [Map<String, String> queryParameters = const {}]) async {
    var client = await _getClient();
    var request = Request('GET', Uri.http('localhost', path, queryParameters));
    _setHeaders(request);
    var response = await client.send(request);
    var lxdResponse = await _parseResponse(response);
    return lxdResponse.result;
  }

  /// Does an asynchronous request to lxd.
  Future<dynamic> _postAsync(String path, [dynamic body]) async {
    var client = await _getClient();
    var request = Request('POST', Uri.http('localhost', path));
    _setHeaders(request);
    request.headers['Content-Type'] = 'application/json';
    request.bodyBytes = utf8.encode(json.encode(body));
    var response = await client.send(request);
    var lxdResponse = await _parseResponse(response);
    return lxdResponse.operation;
  }

  /// Makes base HTTP headers to send.
  void _setHeaders(Request request) {
    if (_userAgent != null) {
      request.headers['User-Agent'] = _userAgent!;
    }
  }

  /// Decodes a response from lxd.
  Future<_LxdResponse> _parseResponse(StreamedResponse response) async {
    var body = await response.stream.bytesToString();
    var jsonResponse = json.decode(body);
    _LxdResponse lxdResponse;
    var type = jsonResponse['type'];
    if (type == 'sync') {
      var statusCode = jsonResponse['status_code'];
      var status = jsonResponse['status'];
      lxdResponse = _LxdSyncResponse(jsonResponse['metadata'],
          statusCode: statusCode, status: status);
    } else if (type == 'async') {
      var statusCode = jsonResponse['status_code'];
      var status = jsonResponse['status'];
      var metadata = jsonResponse['metadata'];
      lxdResponse = _LxdAsyncResponse(_parseOperation(metadata),
          statusCode: statusCode, status: status);
    } else if (type == 'error') {
      var errorCode = jsonResponse['error_code'];
      var error = jsonResponse['error'];
      lxdResponse = _LxdErrorResponse(errorCode: errorCode, error: error);
    } else {
      throw "Unknown lxd response '$type'";
    }

    return lxdResponse;
  }

  LxdOperation _parseOperation(dynamic data) {
    return LxdOperation(
        createdAt: DateTime.parse(data['created_at']),
        description: data['description'],
        error: data['err'],
        id: data['id'],
        status: data['status'],
        statusCode: data['status_code'],
        updatedAt: DateTime.parse(data['updated_at']));
  }
}
