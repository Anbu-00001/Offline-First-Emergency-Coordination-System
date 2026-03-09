import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TileFetchResult {
  final int statusCode;
  final Map<String, String>? headers;
  final Uint8List? bytes;
  final String? error;

  TileFetchResult({
    required this.statusCode,
    this.headers,
    this.bytes,
    this.error,
  });

  bool get isSuccess => statusCode == 200 && bytes != null && bytes!.isNotEmpty;
}

class TileFetchDiagnostic {
  static Future<TileFetchResult> fetchSampleTile(String urlTemplate) async {
    // Generate URL for z=3, x=4, y=3 for a varied sample rather than just ocean
    final url = urlTemplate
        .replaceAll('{z}', '3')
        .replaceAll('{x}', '4')
        .replaceAll('{y}', '3');
    
    debugPrint('Diagnostic: Fetching tile $url');

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      
      final request = await client.getUrl(Uri.parse(url));
      // Important: provide a user-agent so OSM doesn't block us
      request.headers.set('User-Agent', 'org.openrescue.app');
      
      final response = await request.close();
      
      final headers = <String, String>{};
      response.headers.forEach((key, values) {
        headers[key] = values.join(', ');
      });
      
      final bytesBuilder = BytesBuilder();
      await for (var chunk in response) {
        bytesBuilder.add(chunk);
      }
      final bytes = bytesBuilder.takeBytes();
      
      debugPrint('Diagnostic: Tile fetch complete - Status: ${response.statusCode}, Bytes: ${bytes.length}');
      
      client.close();
      return TileFetchResult(
        statusCode: response.statusCode,
        headers: headers,
        bytes: bytes,
      );
    } catch (e) {
      debugPrint('Diagnostic: Tile fetch failed - Error: $e');
      return TileFetchResult(
        statusCode: -1,
        error: e.toString(),
      );
    }
  }
}

class SampleTileWidget extends StatefulWidget {
  final String urlTemplate;
  
  const SampleTileWidget({super.key, required this.urlTemplate});

  @override
  State<SampleTileWidget> createState() => _SampleTileWidgetState();
}

class _SampleTileWidgetState extends State<SampleTileWidget> {
  TileFetchResult? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTile();
  }
  
  @override
  void didUpdateWidget(SampleTileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urlTemplate != widget.urlTemplate) {
      _fetchTile();
    }
  }

  Future<void> _fetchTile() async {
    setState(() => _loading = true);
    final result = await TileFetchDiagnostic.fetchSampleTile(widget.urlTemplate);
    if (mounted) {
      setState(() {
        _result = result;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border.all(color: Colors.greenAccent, width: 2),
      ),
      child: _loading 
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent, strokeWidth: 2))
          : _result?.isSuccess == true
              ? Stack(
                  children: [
                    Image.memory(
                      _result!.bytes!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        color: Colors.green,
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      'FAIL\nHTTP ${_result?.statusCode ?? "ERR"}\n${_result?.error ?? ""}',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 10),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
    );
  }
}
