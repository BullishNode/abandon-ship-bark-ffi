class EsploraEndpointEntity {
  final int _id;
  final String _baseUrl;
  String? _label;
  final String _network;
  int _priority;

  EsploraEndpointEntity({
    required int id,
    required String baseUrl,
    String? label,
    required String network,
    required int priority,
  }) : _id = id,
       _baseUrl = baseUrl,
       _label = label,
       _network = network,
       _priority = priority;

  int get id => _id;
  String get baseUrl => _baseUrl;
  String? get label => _label;
  String get network => _network;
  int get priority => _priority;

  void update({String? newLabel, int? newPriority}) {
    if (newLabel != null) {
      _label = newLabel;
    }
    if (newPriority != null) {
      _priority = newPriority;
    }
  }

  void validate() {
    if (_priority < 0) {
      throw ArgumentError('Priority cannot be negative');
    }
  }
}
